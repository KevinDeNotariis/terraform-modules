# ---------------------------------------------------------------
# 1. Create ECR Repo
# ---------------------------------------------------------------
resource "aws_ecr_repository" "this" {
  name                 = "${local.identifier}-${var.suffix}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  force_delete = contains(local.dev_environments, var.environment) ? true : false

  tags = local.tags
}

# ---------------------------------------------------------------
# 2. Create the Resource Based policy for ECR
# ---------------------------------------------------------------
data "aws_iam_policy_document" "ecr_readonly" {
  count = length(var.ecr_readonly_roles) == 0 ? 0 : 1

  statement {
    sid = "__ReadOnly_Roles"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:DescribeImages",
      "ecr:BatchGetImage",
      "ecr:GetLifecyclePolicy",
      "ecr:GetLifecyclePolicyPreview",
      "ecr:ListTagsForResource",
      "ecr:DescribeImageScanFindings"
    ]

    principals {
      type = "AWS"
      identifiers = [
        for readonly_roles in var.ecr_readonly_roles : format("arn:aws:iam::%s:role/%s",
          data.aws_caller_identity.current.account_id,
          readonly_roles
        )
      ]
    }
  }
}
data "aws_iam_policy_document" "ecr_poweruser" {
  count = length(var.ecr_poweruser_roles) == 0 ? 0 : 1

  statement {
    sid = "__PowerUser_Roles"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:DescribeImages",
      "ecr:BatchGetImage",
      "ecr:GetLifecyclePolicy",
      "ecr:GetLifecyclePolicyPreview",
      "ecr:ListTagsForResource",
      "ecr:DescribeImageScanFindings",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage"
    ]

    principals {
      type = "AWS"
      identifiers = [
        for poweruser_roles in var.ecr_poweruser_roles : format("arn:aws:iam::%s:role/%s",
          data.aws_caller_identity.current.account_id,
          poweruser_roles
        )
      ]
    }
  }
}

data "aws_iam_policy_document" "ecr" {
  count = length(concat(data.aws_iam_policy_document.ecr_readonly, data.aws_iam_policy_document.ecr_poweruser)) > 0 ? 1 : 0

  source_policy_documents = [
    length(data.aws_iam_policy_document.ecr_readonly) > 0 ? data.aws_iam_policy_document.ecr_readonly[0].json : null,
    length(data.aws_iam_policy_document.ecr_poweruser) > 0 ? data.aws_iam_policy_document.ecr_poweruser[0].json : null
  ]
}

resource "aws_ecr_repository_policy" "this" {
  count = length(data.aws_iam_policy_document.ecr) > 0 ? 1 : 0

  repository = aws_ecr_repository.this.name
  policy     = data.aws_iam_policy_document.ecr[0].json
}

# ---------------------------------------------------------------
# 3. Setup Replication of the Repository (for non-dev environments)
# ---------------------------------------------------------------
resource "aws_ecr_replication_configuration" "this" {
  count = contains(local.dev_environments, var.environment) ? 0 : 1

  replication_configuration {
    rule {
      destination {
        region      = var.ecr_replication_region
        registry_id = data.aws_caller_identity.current.account_id
      }

      repository_filter {
        filter      = aws_ecr_repository.this.name
        filter_type = "PREFIX_MATCH"
      }
    }
  }
}

# ---------------------------------------------------------------
# 4. Create ECS Cluster
# ---------------------------------------------------------------
resource "aws_ecs_cluster" "this" {
  name = "${local.identifier}-${var.suffix}"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = local.tags
}

resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name = aws_ecs_cluster.this.name

  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    base              = var.ecs_capacity_provider_base
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

# ---------------------------------------------------------------
# 5. Define the ECS Task
# ---------------------------------------------------------------
# -----------------------------------
# 5.1 Create the IAM Role for
#     the task execution
# -----------------------------------
resource "aws_iam_role" "ecs_execution" {
  name = "${local.identifier}-ecs-execution-${var.suffix}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRole"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  ]

  tags = local.tags
}
data "aws_iam_policy_document" "ecs_execution_load_balancing" {
  statement {
    effect    = "Allow"
    actions   = ["ec2:Describe*"]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
      "elasticloadbalancing:DeregisterTargets",
      "elasticloadbalancing:Describe*",
      "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
      "elasticloadbalancing:RegisterTargets"
    ]
    resources = [var.lb_arn]
  }
}
data "aws_iam_policy_document" "ecs_execution_basic" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeTags",
      "ecs:DeregisterContainerInstance",
      "ecs:DiscoverPollEndpoint",
      "ecs:Poll",
      "ecs:RegisterContainerInstance",
      "ecs:StartTelemetrySession",
      "ecs:UpdateContainerInstancesState",
      "ecs:Submit*",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}
data "aws_iam_policy_document" "ecs_execution_auto_scaling" {
  statement {
    actions = [
      "application-autoscaling:*",
      "ecs:DescribeServices",
      "ecs:UpdateService",
      "cloudwatch:DescribeAlarms",
      "cloudwatch:PutMetricAlarm",
      "cloudwatch:DeleteAlarms",
      "cloudwatch:DescribeAlarmHistory",
      "cloudwatch:DescribeAlarmsForMetric",
      "cloudwatch:GetMetricStatistics",
      "cloudwatch:ListMetrics",
      "cloudwatch:DisableAlarmActions",
      "cloudwatch:EnableAlarmActions",
      "iam:CreateServiceLinkedRole",
      "sns:CreateTopic",
      "sns:Subscribe",
      "sns:Get*",
      "sns:List*"
    ]
    resources = ["*"]
  }
}
data "aws_iam_policy_document" "ecs_execution" {
  source_policy_documents = [
    data.aws_iam_policy_document.ecs_execution_load_balancing.json,
    data.aws_iam_policy_document.ecs_execution_basic.json,
    data.aws_iam_policy_document.ecs_execution_auto_scaling.json
  ]
}
resource "aws_iam_policy" "ecs_execution" {
  name   = "${local.identifier}-ecs-execution-${var.suffix}"
  policy = data.aws_iam_policy_document.ecs_execution.json

  tags = local.tags
}
resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = aws_iam_policy.ecs_execution.arn
}

# -----------------------------------
# 5.2 Create the Log Group where
#     the logs will be placed
# -----------------------------------
resource "aws_cloudwatch_log_group" "ecs" {
  name              = local.ecs_container_log_group_name
  retention_in_days = var.ecs_logs_retention_in_days

  tags = local.tags
}

# -----------------------------------
# 5.3 Get the container definition
# -----------------------------------
data "template_file" "ecs_task_container_definition" {
  template = file("${path.module}/config/container_definitions.json.tpl")

  vars = {
    name          = local.ecs_container_name
    region        = data.aws_region.current.name
    image         = "${aws_ecr_repository.this.repository_url}:${var.ecr_image_version}"
    log_group     = aws_cloudwatch_log_group.ecs.name
    stream_prefix = local.ecs_container_stream_prefix
  }
}

# -----------------------------------
# 5.4 Create the task definition
# -----------------------------------
resource "aws_ecs_task_definition" "this" {
  family                   = "${local.identifier}-${var.suffix}"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.ecs_task_cpu
  memory                   = var.ecs_task_memory
  network_mode             = local.ecs_network_mode

  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }

  # For the first deployment, afterwards, it will be handled by the application repo
  container_definitions = jsonencode(jsondecode(data.template_file.ecs_task_container_definition.rendered))

  execution_role_arn = aws_iam_role.ecs_execution.arn

  lifecycle {
    ignore_changes = [
      container_definitions
    ]
  }

  tags = local.tags
}

# ---------------------------------------------------------------
# 6. Define the ECS Service
# ---------------------------------------------------------------
resource "aws_security_group" "this" {
  name        = "${local.identifier}-ecs-${var.suffix}"
  description = "Allow ingress from VPC and outbound to VPC"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow Inbound Port 80 From VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  # ECS needs access to internet outbound to call the ECR endpoint to pull the image
  egress {
    description = "Allow All Outbound to VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

resource "aws_ecs_service" "this" {
  name             = "${local.identifier}-${var.suffix}"
  cluster          = aws_ecs_cluster.this.id
  task_definition  = aws_ecs_task_definition.this.arn
  desired_count    = var.ecs_service_desired_count
  launch_type      = "FARGATE"
  platform_version = var.ecs_service_platform_version

  network_configuration {
    subnets         = var.private_subnets_ids
    security_groups = [aws_security_group.this.id]
  }

  load_balancer {
    target_group_arn = var.lb_target_group_arn
    container_name   = local.ecs_container_name
    container_port   = 80
  }

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  lifecycle {
    ignore_changes = [desired_count, task_definition, load_balancer, platform_version]
  }

  tags = local.tags
}

# ---------------------------------------------------------------
# 1. Create the codestar connection with github
# ---------------------------------------------------------------
resource "aws_codestarconnections_connection" "this" {
  name          = "${local.identifier}-${var.suffix}"
  provider_type = var.source_provider

  tags = local.tags
}

# ---------------------------------------------------------------
# 2. Create the S3 Bucket to Hold the CodePipeline Artifacts
# ---------------------------------------------------------------
#tfsec:ignore:aws-s3-enable-bucket-logging
resource "aws_s3_bucket" "this" {
  bucket        = "${local.identifier}-codepipeline-artifacts-${var.suffix}"
  force_destroy = contains(local.dev_environments, var.environment)

  tags = local.tags
}

resource "aws_s3_bucket_acl" "this" {
  bucket = aws_s3_bucket.this.id
  acl    = "private"
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_intelligent_tiering_configuration" "this" {
  bucket = aws_s3_bucket.this.id
  name   = "EntireBucket"

  tiering {
    access_tier = "DEEP_ARCHIVE_ACCESS"
    days        = 180
  }

  tiering {
    access_tier = "ARCHIVE_ACCESS"
    days        = 90
  }
}

#tfsec:ignore:aws-s3-encryption-customer-key
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ---------------------------------------------------------------
# 3. Create the IAM Role for CodePipeline
# ---------------------------------------------------------------
resource "aws_iam_role" "codepipeline" {
  name = "${local.identifier}-codepipeline-${var.suffix}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "codepipeline.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = local.tags
}

data "aws_iam_policy_document" "codepipeline" {
  #tfsec:ignore:aws-iam-no-policy-wildcards
  statement {
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "s3:PutObjectAcl",
      "s3:PutObject"
    ]
    resources = [
      "${aws_s3_bucket.this.arn}",
      "${aws_s3_bucket.this.arn}/*"
    ]
  }

  statement {
    actions   = ["codestar-connections:UseConnection"]
    resources = ["${aws_codestarconnections_connection.this.arn}"]
  }

  statement {
    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild"
    ]
    resources = [
      "arn:aws:codebuild:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:project/${aws_codebuild_project.this.name}"
    ]
  }

  statement {
    actions = [
      "codedeploy:CreateDeployment",
      "codedeploy:GetApplicationRevision",
      "codedeploy:GetDeployment",
      "codedeploy:GetDeploymentConfig",
      "codedeploy:RegisterApplicationRevision",
      "codedeploy:GetApplication"
    ]
    resources = [
      format("arn:aws:codedeploy:%s:%s:deploymentgroup:%s/%s",
        data.aws_region.current.name,
        data.aws_caller_identity.current.account_id,
        aws_codedeploy_app.this.name,
        var.deploy_platform == "Server" ? aws_codedeploy_deployment_group.server[0].deployment_group_name : aws_codedeploy_deployment_group.ecs[0].deployment_group_name
      ),
      format("arn:aws:codedeploy:%s:%s:application:%s",
        data.aws_region.current.name,
        data.aws_caller_identity.current.account_id,
        aws_codedeploy_app.this.name,
      ),
      format("arn:aws:codedeploy:%s:%s:deploymentconfig:%s",
        data.aws_region.current.name,
        data.aws_caller_identity.current.account_id,
        var.deploy_platform == "Server" ? aws_codedeploy_deployment_group.server[0].deployment_group_name : aws_codedeploy_deployment_group.ecs[0].deployment_group_name
      ),
      format("arn:aws:codedeploy:%s:%s:deploymentconfig:CodeDeployDefault.ECSAllAtOnce",
        data.aws_region.current.name,
        data.aws_caller_identity.current.account_id,
      ),
    ]
  }

  dynamic "statement" {
    for_each = var.deploy_platform == "ECS" ? [1] : []

    content {
      actions   = ["ecs:RegisterTaskDefinition"]
      resources = ["*"]
    }
  }

  dynamic "statement" {
    for_each = var.deploy_platform == "ECS" ? [1] : []

    content {
      actions = ["iam:PassRole"]
      resources = [
        format("arn:aws:iam::%s:role/%s",
          data.aws_caller_identity.current.account_id,
          var.deploy_ecs_config.execution_role_name
        )
      ]
    }
  }
}

resource "aws_iam_role_policy" "codepipeline" {
  role   = aws_iam_role.codepipeline.id
  policy = data.aws_iam_policy_document.codepipeline.json
}

# ---------------------------------------------------------------
# 4. Create the IAM Role for CodeBuild Container
# ---------------------------------------------------------------
resource "aws_iam_role" "codebuild" {
  name = "${local.identifier}-codebuild-${var.suffix}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "codebuild.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = local.tags
}

data "aws_iam_policy_document" "codebuild" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = [aws_cloudwatch_log_group.this.arn, "${aws_cloudwatch_log_group.this.arn}:*"]
  }

  #tfsec:ignore:aws-iam-no-policy-wildcards
  statement {
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "s3:PutObjectAcl",
      "s3:PutObject"
    ]
    resources = [
      "${aws_s3_bucket.this.arn}",
      "${aws_s3_bucket.this.arn}/*"
    ]
  }

  statement {
    actions = [
      "codebuild:CreateReportGroup",
      "codebuild:CreateReport",
      "codebuild:UpdateReport",
      "codebuild:BatchPutTestCases",
      "codebuild:BatchPutCodeCoverages",
    ]
    resources = [format("arn:aws:codebuild:%s:%s:report-group/*",
      data.aws_region.current.name,
      data.aws_caller_identity.current.account_id,
    )]
  }

  dynamic "statement" {
    for_each = var.deploy_platform == "ECS" ? [1] : []

    content {
      actions = [
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability",
        "ecr:CompleteLayerUpload",
        "ecr:GetDownloadUrlForLayer",
        "ecr:InitiateLayerUpload",
        "ecr:PutImage",
        "ecr:UploadLayerPart"
      ]
      resources = [var.deploy_ecs_config.ecr_repo_arn]
    }
  }

  dynamic "statement" {
    for_each = var.deploy_platform == "ECS" ? [1] : []

    content {
      actions   = ["ecr:GetAuthorizationToken"]
      resources = ["*"]
    }
  }

  dynamic "statement" {
    for_each = var.deploy_platform == "ECS" ? [1] : []

    content {
      actions = [
        "ec2:CreateNetworkInterface",
        "ec2:DescribeDhcpOptions",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DeleteNetworkInterface",
        "ec2:DescribeSubnets",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeVpcs"
      ]
      resources = ["*"]
    }
  }

  dynamic "statement" {
    for_each = var.deploy_platform == "ECS" ? [1] : []

    content {
      actions   = ["ec2:CreateNetworkInterfacePermission"]
      resources = ["arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:network-interface/*"]
      condition {
        test     = "StringEquals"
        variable = "ec2:AuthorizedService"
        values   = ["codebuild.amazonaws.com"]
      }
      condition {
        test     = "ArnEquals"
        variable = "ec2:Subnet"
        values = [
          for subnet_id in var.private_subnets_ids : "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:subnet/${subnet_id}"
        ]
      }
    }
  }
}

resource "aws_iam_role_policy" "codebuild" {
  role   = aws_iam_role.codebuild.id
  policy = data.aws_iam_policy_document.codebuild.json
}

# ---------------------------------------------------------------
# 5. Create IAM Role for CodeDeploy
# ---------------------------------------------------------------
resource "aws_iam_role" "codedeploy" {
  name = "${local.identifier}-codedeploy-${var.suffix}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "codedeploy.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "codedeploy" {
  role = aws_iam_role.codedeploy.id
  policy_arn = format("arn:aws:iam::aws:policy/%s",
    var.deploy_platform == "Server" ? "service-role/AWSCodeDeployRole" : "AWSCodeDeployRoleForECS"
  )
}

# ---------------------------------------------------------------
# 6. Create the CloudWatch log group for CodeBuild outputs
# ---------------------------------------------------------------
#tfsec:ignore:aws-cloudwatch-log-group-customer-key
resource "aws_cloudwatch_log_group" "this" {
  name = format("%s-%s-%s/%s",
    local.identifier,
    "codepipeline",
    var.suffix,
    "build-logs"
  )
  retention_in_days = var.build_logs_retention

  tags = local.tags
}

# ---------------------------------------------------------------
# 7. Create the CodeBuild Project
# ---------------------------------------------------------------
resource "aws_security_group" "codebuild" {
  count = var.deploy_platform == "ECS" ? 1 : 0

  name   = "${local.identifier}-codebuild-${var.suffix}"
  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}
resource "aws_codebuild_project" "this" {
  name               = "${local.identifier}-${var.suffix}"
  description        = "Build Stage for ${local.identifier}"
  build_timeout      = var.build_timeout
  service_role       = aws_iam_role.codebuild.arn
  queued_timeout     = var.build_queue_timeout
  project_visibility = "PRIVATE"

  artifacts {
    type = "CODEPIPELINE"
  }

  cache {
    type = "NO_CACHE"
  }

  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.this.name
    }

    s3_logs {
      status   = "ENABLED"
      location = format("%s/%s", aws_s3_bucket.this.id, "build-logs")
    }
  }

  # To Allow Docker Pull on the DockerHub, otherwise we get:
  # toomanyrequests: You have reached your pull rate limit. You may increase the limit by authenticating and upgrading: https://www.docker.com/increase-rate-limit
  dynamic "vpc_config" {
    for_each = var.deploy_platform == "ECS" ? [1] : []

    content {
      vpc_id             = var.vpc_id
      subnets            = var.private_subnets_ids
      security_group_ids = [aws_security_group.codebuild[0].id]
    }
  }

  environment {
    compute_type                = var.build_image_type
    image                       = var.build_image
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = var.deploy_platform == "ECS"
    type                        = "LINUX_CONTAINER"

    dynamic "environment_variable" {
      for_each = var.deploy_platform == "ECS" ? {
        ECR_AWS_ACCOUNT_ID           = data.aws_caller_identity.current.account_id
        ECR_IMAGE_REPO_NAME          = var.deploy_ecs_config.ecr_repo_name
        ECR_IMAGE_REPO_URL           = var.deploy_ecs_config.ecr_repo_url
        ECR_IMAGE_TAG                = "latest"
        ECS_EXECUTION_ROLE_ARN       = var.deploy_ecs_config.execution_role_arn
        ECS_FAMILY                   = var.deploy_ecs_config.family
        ECS_CPU                      = var.deploy_ecs_config.cpu
        ECS_MEMORY                   = var.deploy_ecs_config.memory
        ECS_NETWORK_MODE             = var.deploy_ecs_config.network_mode
        ECS_CONTAINER_REGION         = data.aws_region.current.name
        ECS_CONTAINER_NAME           = var.deploy_ecs_config.container_name
        ECS_CONTAINER_LOG_GROUP_NAME = var.deploy_ecs_config.container_log_group_name
        ECS_CONTAINER_STREAM_PREFIX  = var.deploy_ecs_config.container_stream_prefix
      } : {}
      content {
        name  = environment_variable.key
        value = environment_variable.value
      }
    }

    dynamic "environment_variable" {
      for_each = var.build_env_variables

      content {
        name  = environment_variable.key
        value = environment_variable.value
      }
    }
  }

  source {
    type = "CODEPIPELINE"
  }

  tags = local.tags
}

# ---------------------------------------------------------------
# 8. Create the CodeDeploy Application and Group
# ---------------------------------------------------------------
resource "aws_codedeploy_app" "this" {
  name             = "${local.identifier}-${var.suffix}"
  compute_platform = var.deploy_platform

  tags = local.tags
}

resource "aws_codedeploy_deployment_group" "ecs" {
  count = var.deploy_platform == "ECS" ? 1 : 0

  app_name               = aws_codedeploy_app.this.name
  deployment_group_name  = "${local.identifier}-${var.suffix}"
  service_role_arn       = aws_iam_role.codedeploy.arn
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }
  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }
    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }
  }
  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }
  ecs_service {
    cluster_name = var.deploy_ecs_config.cluster_name
    service_name = var.deploy_ecs_config.service_name
  }
  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [var.deploy_ecs_config.lb_listener_arn]
      }
      target_group {
        name = var.deploy_ecs_config.lb_target_group_blue_name
      }
      target_group {
        name = var.deploy_ecs_config.lb_target_group_green_name
      }
    }
  }

  trigger_configuration {
    trigger_events = [
      "DeploymentStart",
      "DeploymentSuccess",
      "DeploymentFailure",
      "DeploymentStop",
      "DeploymentRollback"
    ]
    trigger_name       = "deployment-events"
    trigger_target_arn = var.deploy_trigger_target_arn
  }

  tags = local.tags
}

resource "aws_codedeploy_deployment_group" "server" {
  count = var.deploy_platform == "Server" ? 1 : 0

  app_name              = aws_codedeploy_app.this.name
  deployment_group_name = "${local.identifier}-${var.suffix}"
  service_role_arn      = aws_iam_role.codedeploy.arn

  autoscaling_groups = [
    var.deploy_server_config.ag_id
  ]

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  deployment_style {
    deployment_type   = "IN_PLACE"
    deployment_option = "WITH_TRAFFIC_CONTROL"
  }

  load_balancer_info {
    target_group_info {
      name = var.deploy_server_config.lb_target_group_name
    }
  }

  trigger_configuration {
    trigger_events = [
      "DeploymentStart",
      "DeploymentSuccess",
      "DeploymentFailure",
      "DeploymentStop",
      "DeploymentRollback"
    ]
    trigger_name       = "deployment-events"
    trigger_target_arn = var.deploy_trigger_target_arn
  }

  tags = local.tags
}

# ---------------------------------------------------------------
# 9. Add IAM permissions to the EC2 instances role to get the
#    artifact from s3
# ---------------------------------------------------------------
data "aws_iam_policy_document" "ec2_codedeploy_server" {
  count = var.deploy_platform == "Server" ? 1 : 0
  statement {
    actions = [
      "s3:Get*",
      "s3:List*",
    ]
    resources = [
      "${aws_s3_bucket.this.arn}",
      "${aws_s3_bucket.this.arn}/*"
    ]
  }
}

resource "aws_iam_role_policy" "ec2_codedeploy_server" {
  count = var.deploy_platform == "Server" ? 1 : 0

  role   = var.deploy_server_config.ag_ec2_iam_role_name
  policy = data.aws_iam_policy_document.ec2_codedeploy_server[0].json
}

# ---------------------------------------------------------------
# 10. Create the CodePipeline Pipeline
# ---------------------------------------------------------------
resource "aws_codepipeline" "this" {
  name     = "${local.identifier}-${var.suffix}"
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    location = aws_s3_bucket.this.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.this.arn
        FullRepositoryId = var.source_repo_id
        BranchName       = var.source_branch_name
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.this.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = var.deploy_platform == "Server" ? "CodeDeploy" : "CodeDeployToECS"
      input_artifacts = ["build_output"]
      version         = "1"

      configuration = var.deploy_platform == "Server" ? {
        ApplicationName     = aws_codedeploy_app.this.name
        DeploymentGroupName = aws_codedeploy_deployment_group.server[0].deployment_group_name
        } : {
        ApplicationName                = aws_codedeploy_app.this.name
        DeploymentGroupName            = aws_codedeploy_deployment_group.ecs[0].deployment_group_name
        TaskDefinitionTemplateArtifact = "build_output"
        AppSpecTemplateArtifact        = "build_output"
      }
    }
  }

  tags = local.tags
}

# ---------------------------------------------------------------
# 11. Create CodeStar Notification Rule for CodePipeline Events
# ---------------------------------------------------------------
resource "aws_codestarnotifications_notification_rule" "this" {
  name        = "${local.identifier}-${var.suffix}"
  detail_type = "FULL"
  event_type_ids = [
    "codepipeline-pipeline-pipeline-execution-failed",
    "codepipeline-pipeline-pipeline-execution-canceled",
    "codepipeline-pipeline-pipeline-execution-started",
    "codepipeline-pipeline-pipeline-execution-resumed",
    "codepipeline-pipeline-pipeline-execution-succeeded",
    "codepipeline-pipeline-pipeline-execution-superseded"
  ]
  resource = aws_codepipeline.this.arn

  target {
    type    = "SNS"
    address = var.pipeline_notification_target_arn
  }

  tags = local.tags
}

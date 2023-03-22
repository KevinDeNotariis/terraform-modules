# ---------------------------------------------------------------
# 1. Define the Security Groups that the instances will have
# ---------------------------------------------------------------
resource "aws_security_group" "this" {
  name        = "${local.identifier}-autoscaling-${var.suffix}"
  description = "Allow ingress from VPC and outbound to VPC with 443 open for SSM"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow Inbound Port 80 From VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  #tfsec:ignore:aws-ec2-no-public-egress-sgr
  egress {
    description = "Allow 443 Outbound to SSM endpoints"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow All Outbound to VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr_block]
  }

  tags = local.tags
}

# ---------------------------------------------------------------
# 2.1 Create the IAM role for the EC2 instance profile
# ---------------------------------------------------------------
resource "aws_iam_role" "this" {
  name = "${local.identifier}-autoscaling-${var.suffix}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRole"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
  ]

  tags = local.tags
}

# ---------------------------------------------------------------
# 2.2 Let the EC2 access secrets manager to get the DB creds
# ---------------------------------------------------------------
data "aws_iam_policy_document" "this" {
  statement {
    actions = [
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecretVersionIds"
    ]
    resources = [
      "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.id}:secret:${var.db_creds_secret_id}"
    ]
  }
}

resource "aws_iam_role_policy" "this" {
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.this.json
}

# ---------------------------------------------------------------
# 3. Create the Instance Profile for the EC2 instances and 
#    assign the above IAM role
# ---------------------------------------------------------------
resource "aws_iam_instance_profile" "this" {
  name = "${local.identifier}-autoscaling-${var.suffix}"
  role = aws_iam_role.this.name

  tags = local.tags
}

# ---------------------------------------------------------------
# 4. Create the Launch Template
# ---------------------------------------------------------------
resource "aws_launch_template" "this" {
  name                   = "${local.identifier}-autoscaling-${var.suffix}"
  description            = "Configuration for ${local.identifier}"
  image_id               = var.image_id
  instance_type          = var.instance_type
  user_data              = base64encode(var.user_data)
  vpc_security_group_ids = [aws_security_group.this.id]
  update_default_version = true

  iam_instance_profile {
    name = aws_iam_instance_profile.this.name
  }

  instance_initiated_shutdown_behavior = "terminate"

  monitoring {
    enabled = true
  }

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      delete_on_termination = true
      volume_size           = 8
      encrypted             = true
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  tags = local.tags
}

# ---------------------------------------------------------------
# 5. Create the Autoscaling Groups
# ---------------------------------------------------------------
resource "aws_autoscaling_group" "this" {
  name                      = "${local.identifier}-autoscaling-${var.suffix}"
  vpc_zone_identifier       = var.private_subnets_ids
  min_size                  = var.min_size
  max_size                  = var.max_size
  health_check_type         = "EC2"
  health_check_grace_period = 120
  wait_for_capacity_timeout = "10m"
  default_cooldown          = 120
  termination_policies      = ["Default"]
  target_group_arns         = [var.lb_target_group_arn]
  lifecycle {
    create_before_destroy = true
  }

  launch_template {
    id      = aws_launch_template.this.id
    version = aws_launch_template.this.latest_version
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 80
    }
  }

  tag {
    key                 = "Name"
    value               = "${local.identifier}-${var.suffix}"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = local.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

# ---------------------------------------------------------------
# 6. Create the Autoscaling Policies
# ---------------------------------------------------------------
resource "aws_autoscaling_policy" "this" {
  name                   = "${local.identifier}-${var.suffix}"
  autoscaling_group_name = aws_autoscaling_group.this.name
  policy_type            = "SimpleScaling"
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 60.0
  }
}

# ---------------------------------------------------------------
# 7. Create the notifications for Autoscaling events
# ---------------------------------------------------------------
resource "aws_autoscaling_notification" "this" {
  group_names = [aws_autoscaling_group.this.name]
  notifications = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR"
  ]
  topic_arn = var.asg_sns_arn
}

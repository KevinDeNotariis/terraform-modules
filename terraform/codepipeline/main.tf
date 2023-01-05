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
      "codedeploy:RegisterApplicationRevision"
    ]
    resources = [
      format("arn:aws:codedeploy:%s:%s:deploymentgroup:%s/%s",
        data.aws_region.current.name,
        data.aws_caller_identity.current.account_id,
        aws_codedeploy_app.this.name,
        aws_codedeploy_deployment_group.this.deployment_group_name
      ),
      format("arn:aws:codedeploy:%s:%s:application:%s",
        data.aws_region.current.name,
        data.aws_caller_identity.current.account_id,
        aws_codedeploy_app.this.name,
      ),
      format("arn:aws:codedeploy:%s:%s:deploymentconfig:%s",
        data.aws_region.current.name,
        data.aws_caller_identity.current.account_id,
        aws_codedeploy_deployment_group.this.deployment_config_name
      ),
    ]
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
  role       = aws_iam_role.codedeploy.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
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

  environment {
    compute_type                = var.build_image_type
    image                       = "aws/codebuild/standard:5.0"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = false
    type                        = "LINUX_CONTAINER"
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
  compute_platform = "Server"

  tags = local.tags
}

resource "aws_codedeploy_deployment_group" "this" {
  app_name              = aws_codedeploy_app.this.name
  deployment_group_name = "${local.identifier}-${var.suffix}"
  service_role_arn      = aws_iam_role.codedeploy.arn

  autoscaling_groups = [
    var.deploy_ag_id
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
      name = var.deploy_lb_target_group_name
    }
  }

  tags = local.tags
}

# ---------------------------------------------------------------
# 9. Add IAM permissions to the EC2 instances role to get the
#    artifact from s3
# ---------------------------------------------------------------
data "aws_iam_policy_document" "ec2_codedeploy" {
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

resource "aws_iam_role_policy" "ec2_codedeploy" {
  role   = var.deploy_ag_ec2_iam_role_name
  policy = data.aws_iam_policy_document.ec2_codedeploy.json
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
      provider        = "CodeDeploy"
      input_artifacts = ["build_output"]
      version         = "1"

      configuration = {
        ApplicationName     = aws_codedeploy_app.this.name
        DeploymentGroupName = aws_codedeploy_deployment_group.this.deployment_group_name
      }
    }
  }

  tags = local.tags
}

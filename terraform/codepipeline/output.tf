output "s3_artifacts_bucket_name" {
  value = aws_s3_bucket.this.bucket
}

output "codepipeline_iam_role_arn" {
  value = aws_iam_role.codepipeline.arn
}

output "codebuild_iam_role_arn" {
  value = aws_iam_role.codebuild.arn
}

output "codebuild_project_name" {
  value = aws_codebuild_project.this.name
}

output "codedeploy_iam_role_arn" {
  value = aws_iam_role.codedeploy.arn
}

output "codedeploy_app_name" {
  value = aws_codedeploy_app.this.name
}

output "codedeploy_deployment_group_name" {
  value = aws_codedeploy_deployment_group.this.deployment_group_name
}

output "codebuild_log_group_arn" {
  value = aws_cloudwatch_log_group.this.arn
}

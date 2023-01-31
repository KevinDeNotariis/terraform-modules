variable "identifier" {
  description = "The identifier for each resource deployed by the module"
  type        = string
}

variable "environment" {
  description = "The environment where the resources will belong to; this will determine some characteristics enabling deletion protection or not"
  type        = string
}

variable "suffix" {
  description = "The suffix which will be happended to each resource; usually a random id"
  type        = string
}

variable "source_provider" {
  description = "Codestar connection provider to allow the creation of a webhook in the remote to trigger the pipeline"
  type        = string
  default     = "GitHub"
}

variable "source_repo_id" {
  description = "The ID the repository where the code resides; for GitHub, something like {owner}/{repo_name}"
  type        = string
}

variable "source_branch_name" {
  description = "The branch that should trigger the pipeline"
  type        = string
  default     = "master"
}

variable "build_image_type" {
  description = "The image that should be used for the build phase in CodeBuild"
  type        = string
  default     = "BUILD_GENERAL1_SMALL"
}

variable "build_image" {
  description = "The image that should be used for the CodeBuild container"
  type        = string
  default     = "aws/codebuild/standard:5.0"
}

variable "build_timeout" {
  description = "The timeout for the build phase in minutes"
  type        = number
  default     = 20
}

variable "build_queue_timeout" {
  description = "The timeout in minutes before the queued jobs should be dropped"
  type        = number
  default     = 480
}

variable "build_logs_retention" {
  description = "The retention in days for the build phase logs"
  type        = number
  default     = 30
}

variable "deploy_ag_id" {
  description = "The autoscaling group ID where the artifacts should be deployed"
  type        = string
}

variable "deploy_ag_ec2_iam_role_name" {
  description = "The IAM role name of the autoscaling group's ec2 instances where the permissions to interact with the S3 buckets holding the artifacts are attached to"
  type        = string
}

variable "deploy_lb_target_group_name" {
  description = "The load balancer in front of the autoscaling group"
  type        = string
}

variable "deploy_trigger_target_arn" {
  description = "The Arn of the target SNS where to send information regarding the deployment progress"
  type        = string
}

variable "pipeline_notification_target_arn" {
  description = "The SNS notification arn where the pipeline stages will be sent to"
  type        = string
}

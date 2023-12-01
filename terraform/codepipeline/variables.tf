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

variable "vpc_id" {
  description = "The VPC's Id where codebuild will run"
  type        = string
  default     = ""
}

variable "private_subnets_ids" {
  description = "The ids of the private subnets"
  type        = list(string)
  default     = []
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
  default     = "aws/codebuild/standard:6.0"
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

variable "deploy_platform" {
  description = "The platform where we want to deploy to"
  type        = string
  default     = "Server"
  validation {
    condition     = contains(["ECS", "Server"], var.deploy_platform)
    error_message = "The deploy_platform variable can only be one of: 'ECS', 'Server'."
  }
}

variable "deploy_server_config" {
  description = "All the configurations of CodeDeploy for Server deployments"
  type = object({
    # The autoscaling group ID where the artifacts should be deployed
    ag_id = string

    # The IAM role name of the autoscaling group's ec2 instances where the permissions to interact with the S3 buckets holding the artifacts are attached to
    ag_ec2_iam_role_name = string

    # The load balancer in front of the autoscaling group
    lb_target_group_name = string
  })
  default = null
}

variable "deploy_ecs_config" {
  description = "All the configurations of CodeDeploy for ECS deployments"
  type = object({
    # The name of the ECS cluster we are going to interact with
    cluster_name = string

    # The name of the ECS service we are going to interact with
    service_name = string

    # The task role arn allowing containers to interact with AWS APIs
    task_role_arn  = string
    task_role_name = string

    # The execution role arn and name of the ECS task
    execution_role_arn  = string
    execution_role_name = string

    # The family of the ECS task
    family = string

    # The network mode of the ECS cluster
    network_mode = string

    # The memory for the ECS task
    memory = number

    # The CPU for the ECS task
    cpu = number

    # The arn of the load balancer's listener in front of the ECS
    lb_listener_arn = string

    # The target group for the "blue" environment
    lb_target_group_blue_name = string

    # The target group for the "green" environment
    lb_target_group_green_name = string

    # The Arn of the ECR repo
    ecr_repo_arn = string

    # The ECR repo name where the image to be deployed is stored
    ecr_repo_name = string

    # The ECR repo url where the image to be deployed is stored
    ecr_repo_url = string

    # Information regarding the container definition for the ECS task
    container_name           = string
    container_log_group_name = string
    container_stream_prefix  = string
  })
  default = null
}

variable "build_env_variables" {
  description = "Environment variables for the codebuild container"
  type        = map(string)
  default     = {}
}

variable "deploy_trigger_target_arn" {
  description = "The Arn of the target SNS where to send information regarding the deployment progress"
  type        = string
}

variable "pipeline_notification_target_arn" {
  description = "The SNS notification arn where the pipeline stages will be sent to"
  type        = string
}

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
  description = "The VPC's Id where the load balancer will be placed into"
  type        = string
}

variable "vpc_cidr_block" {
  description = "The cidr block of the vpc to allow communications within it"
  type        = string
}

variable "private_subnets_ids" {
  description = "The ids of the private subnets"
  type        = list(string)
}

variable "ecr_readonly_roles" {
  description = "Role names that will have readonly access to the ECR repository"
  type        = list(string)
  default     = []
}

variable "ecr_poweruser_roles" {
  description = "Role names that will have power user access to the ECR repository"
  type        = list(string)
  default     = []
}

variable "ecr_replication_region" {
  description = "The region where the repo should be replicated to (only for prod environments)"
  type        = string
  default     = ""
}

variable "ecr_image_version" {
  description = "The version that the ECS FARGATE task will pull down from ECR"
  type        = string
  default     = "latest"
}

variable "ecs_capacity_provider_base" {
  description = "The base attribute for the ECS cluster capacity provider 'fargate'"
  type        = number
  default     = 1
}

variable "ecs_logs_retention_in_days" {
  description = "Retention in days for the Cloudwatch logs of the ECS FARGATE task"
  type        = number
  default     = 7
}

variable "ecs_task_cpu" {
  description = "The CPU to associate to the ECS FARGATE task"
  type        = number
  default     = 256
}

variable "ecs_task_memory" {
  description = "The memory to associate to the ECS FARGATE task"
  type        = number
  default     = 512
}

variable "ecs_service_desired_count" {
  description = "The number of tasks instances to create and run. Only on the first deployment"
  type        = number
  default     = 1
}

variable "ecs_service_platform_version" {
  description = "The Platform version for the ECS farget service"
  type        = string
  default     = "LATEST"
}

variable "lb_arn" {
  description = "The Arn of the Load Balancer placed in front of the ECS cluster"
  type        = string
}

variable "lb_target_group_arn" {
  description = "The load balancer target group which will be associated to the FARGET cluster"
  type        = string
}

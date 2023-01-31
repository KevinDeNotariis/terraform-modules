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

variable "max_capacity" {
  description = "The maximum capacity that can afford the autoscaling"
  type        = number
  default     = 3
}

variable "min_capacity" {
  description = "The minimum capacity that needs to be present"
  type        = number
  default     = 1
}

variable "ecs_cluster_name" {
  description = "The ECS cluster to associate with the autoscaling"
  type        = string
}

variable "ecs_service_name" {
  description = "The ECS service name to associate with the autoscaling"
  type        = string
}

variable "scaling_memory_trigger" {
  description = "The percentage in average memory utilization to trigger an autoscaling action"
  type        = number
  default     = 70
}

variable "scaling_cpu_trigger" {
  description = "The percentage in average cpu utilization to trigger an autoscaling action"
  type        = number
  default     = 70
}

variable "scaling_sns_arn" {
  description = "The SNS arn where the autoscaling events will be published to"
  type        = string
}

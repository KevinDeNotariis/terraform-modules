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

variable "user_data" {
  description = "The user data for the ec2 instances in the autoscaling group"
  type        = string
}

variable "instance_type" {
  description = "The class of the instances in the autoscaling group"
  type        = string
  default     = "t4g.nano"
}

variable "image_id" {
  description = "The AMI id for the instances in the autoscaling group"
  type        = string
  default     = "ami-0abe92d15a280b758"
}

variable "min_size" {
  description = "The minimum number of instances in the autoscaling group"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "The maximum number of instances in the autoscaling group"
  type        = number
  default     = 3
}

variable "desired_capacity" {
  description = "The desired number of instances that should be running in normal condition in the autoscaling group"
  type        = number
  default     = 2
}

variable "lb_sg_id" {
  description = "The security group's id of the load balancer to allow inbound from it"
  type        = string
}

variable "lb_target_group_arn" {
  description = "The Arn of the load balancer's target group to associate the autoscaling group with the load balancer"
  type        = string
}

variable "private_subnets_ids" {
  description = "The private subnet's ids where the instances will live"
  type        = list(string)
}

variable "vpc_id" {
  description = "The vpc id where the instances will live"
  type        = string
}

variable "vpc_cidr_block" {
  description = "The cidr block of the vpc to allow communications within it"
  type        = string
}

variable "db_creds_secret_id" {
  description = "The id of the secret in secrets manager holding the DB credentials; This is used to give the ec2 instances the permissions to access this secret"
  type        = string
}

variable "asg_sns_arn" {
  description = "The SNS arn where the autoscaling group events will be published to"
  type        = string
}

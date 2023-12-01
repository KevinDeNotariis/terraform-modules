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
  description = "The VPC's CIDR block to use in the load balancer security groups"
  type        = string
}

variable "public_subnets_ids" {
  description = "The public subnets IDs where the load balancer will be placed"
  type        = list(string)
}

variable "root_domain_name" {
  description = "The root domain name where the Load Balancer CNAME will be created"
  type        = string
}

variable "lb_subdomain" {
  description = "The subdomain that will be used to create the CNAME for the load balancer. If empty, the subdomain will default to {identifier}.{environment}"
  type        = string
  default     = null
}

variable "lb_cname_ttl" {
  description = "The TTL for the load balancer CNAME"
  type        = number
}

variable "lb_target_type" {
  description = "The target type for the load balancer target group"
  type        = string
  default     = "instance"
}

variable "enable_green_lb_target_group" {
  description = "Whether to create a second target group for blue/green deployment. Specifically for ECS with CodeDeploy"
  type        = bool
  default     = false
}

variable "lb_ignore_listeners_changes" {
  description = "Whether terraform should ignore changes in the lister's target groups, i.e. for an ECS blue/green deployment"
  type        = bool
  default     = false
}

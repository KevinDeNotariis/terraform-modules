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
  description = "The root domain name where the Load Balancer CNAME will be created with a naming convention of: {identifier}.{environment}.{root_domain_name}"
  type        = string
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


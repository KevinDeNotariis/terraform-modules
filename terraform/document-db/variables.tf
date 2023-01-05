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

variable "instance_count" {
  description = "Number of instances in the DB's cluster"
  type        = number
  default     = 1
}

variable "instance_class" {
  description = "The class of the DB instances"
  type        = string
  default     = "db.t3.medium"
}

variable "db_creds_secret_id" {
  description = "The Id of the secret stored in secrets manager holding the database master credentials"
  type        = string
}

variable "ag_ec2_sg_id" {
  description = "The autoscaling the security group's id to allow inbound and outbound in and from the ec2 instances in that autoscaling group"
  type        = string
}

variable "private_subnets_ids" {
  description = "The private subnet's ids where the cluster will live"
  type        = list(string)
}

variable "vpc_id" {
  description = "The vpc id where the cluster will live"
  type        = string
}

variable "identifier" {
  description = "Identifier for each resource that is created"
  type        = string
}

variable "environment" {
  description = "The environment where the resources will belong to; this will determine some characteristics enabling deletion protection or not"
  type        = string
}

variable "suffix" {
  description = "Suffix that is happended to each resource"
  type        = string
}

variable "root_domain_name" {
  description = "The root domain name that is used to create the Private Hosted Zone associated with the VPC"
  type        = string
  default     = null
}

variable "private_subnets_new_bits" {
  description = "The mask's new bits for the private subnets"
  type        = number
}

variable "public_subnets_new_bits" {
  description = "The mask's new bits for the public subnets"
  type        = number
}

# -------------------------------------------------------------------------------------
# No IPAM
# -------------------------------------------------------------------------------------
variable "vpc_cidr_block" {
  description = "CIDR Block of the VPC"
  type        = string
  default     = null
}

# -------------------------------------------------------------------------------------
# With IPAM
# -------------------------------------------------------------------------------------
variable "vpc_cidr_mask" {
  description = "The mask for the VPC CIDR"
  type        = number
  default     = null
}

variable "ipam_pool_id" {
  description = "The ID of the IPAM pool where the VPC CIDR should be taken from"
  type        = string
  default     = null
}

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

variable "sns_general_subscriptions" {
  description = "The map with subscriptions for the general SNS"
  type = list(object({
    protocol = string
    endpoint = string
  }))
}

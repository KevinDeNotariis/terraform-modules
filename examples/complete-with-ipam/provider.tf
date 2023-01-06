terraform {
  required_providers {
    test = {
      source = "terraform.io/builtin/test"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4"
    }
  }
  required_version = "~> 1"
}

provider "aws" {
  region = "eu-west-1"

  default_tags {
    tags = {
      owner       = "kevin de notariis"
      repo        = "github.com/KevinDeNotariis/terraform-modules"
      path        = "examples/complete"
      environment = "test"
    }
  }
}

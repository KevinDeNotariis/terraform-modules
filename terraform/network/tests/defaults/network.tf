locals {
  identifier = "tests-defaults"
}

resource "random_id" "this" {
  byte_length = 4
}

module "network" {
  source = "../.."

  identifier  = local.identifier
  environment = "test"
  suffix      = random_id.this.hex

  vpc_cidr_block           = "10.0.0.0/16"
  private_subnets_new_bits = 8
  public_subnets_new_bits  = 8
}

resource "test_assertions" "subnets" {
  component = "subnets"

  equal "private_subnets_cidr_blocks" {
    description = "private subnets cidr blocks should be taken correctly from the vpc_cidr_block"
    got         = module.network.private_subnets_cidr_blocks
    want        = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]
  }

  equal "public_subnets_cidr_blocks" {
    description = "public subnets cidr blocks should be taken correctly from the vpc_cidr_block"
    got         = module.network.public_subnets_cidr_blocks
    want        = ["10.0.3.0/24", "10.0.4.0/24", "10.0.5.0/24"]
  }
}

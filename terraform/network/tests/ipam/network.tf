locals {
  identifier = "tests-ipam"
}

resource "random_id" "this" {
  byte_length = 4
}

module "network" {
  source = "../.."

  identifier  = local.identifier
  environment = "test"
  suffix      = random_id.this.hex

  vpc_cidr_mask            = 24
  ipam_pool_id             = data.aws_vpc_ipam_pool.dev.id
  private_subnets_new_bits = 3
  public_subnets_new_bits  = 3
}

resource "test_assertions" "subnets" {
  component = "subnets"

  equal "private_subnets_cidr_blocks_size" {
    description = "private subnets cidr blocks size should be correct"
    got         = [for cidr_block in module.network.private_subnets_cidr_blocks : split("/", cidr_block)[1]]
    want        = ["27", "27", "27"]
  }

  equal "public_subnets_cidr_blocks" {
    description = "public subnets cidr blocks size should be correct"
    got         = [for cidr_block in module.network.public_subnets_cidr_blocks : split("/", cidr_block)[1]]
    want        = ["27", "27", "27"]
  }
}

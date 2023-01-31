
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_vpc_ipam_pool" "dev" {
  filter {
    name   = "tag:Name"
    values = ["dev"]
  }
}

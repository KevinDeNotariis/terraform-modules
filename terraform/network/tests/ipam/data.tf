data "aws_vpc_ipam_pool" "dev" {
  filter {
    name   = "tag:Name"
    values = ["dev"]
  }
}

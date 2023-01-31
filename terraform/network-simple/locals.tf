locals {
  identifier = "${var.identifier}-${var.environment}"

  subnets_cidr_blocks = cidrsubnets(
    aws_vpc.this.cidr_block,
    var.private_subnets_new_bits,
    var.private_subnets_new_bits,
    var.private_subnets_new_bits,
    var.public_subnets_new_bits,
    var.public_subnets_new_bits,
    var.public_subnets_new_bits,
  )

  private_subnets_cidr_blocks = slice(local.subnets_cidr_blocks, 0, 3)

  public_subnets_cidr_blocks = slice(local.subnets_cidr_blocks, 3, 6)

  availability_zones = slice(data.aws_availability_zones.available.names, 0, 3)

  # This is the exact equivalent of a zipmap() function. Using the zipmap function in the for_each, however,
  # led to the following error:
  #
  # │ Error: Invalid for_each argument
  # │
  # │   on ../../main.tf line 49, in resource "aws_subnet" "private":
  # │   49:   for_each = zipmap(local.availability_zones, local.private_subnets_cidr_blocks)
  # │     ├────────────────
  # │     │ local.availability_zones is list of string with 3 elements
  # │     │ local.private_subnets_cidr_blocks is a list of string, known only after apply
  # │
  # │ The "for_each" map includes keys derived from resource attributes that cannot be determined until apply, and so Terraform cannot determine the full  
  # │ set of keys that will identify the instances of this resource.
  # │
  # │ When working with unknown values in for_each, it's better to define the map keys statically in your configuration and place apply-time results only  
  # │ in the map values.
  # │
  # │ Alternatively, you could use the -target planning option to first apply only the resources that the for_each value depends on, and then apply a      
  # │ second time to fully converge.
  #
  # Even though both the keys and the number of keys should be known by terraform, it gives the above error when
  # using zipmap. To fix that, the following custom implementation of it works fine.
  az_private_subnets_map = {
    for i, az in local.availability_zones : az => [
      for j, private_subnet in local.private_subnets_cidr_blocks : private_subnet if i == j
    ][0]
  }

  az_public_subnets_map = {
    for i, az in local.availability_zones : az => [
      for j, public_subnet in local.public_subnets_cidr_blocks : public_subnet if i == j
    ][0]
  }

  tags = {
    "module:name"  = "network-simple"
    "module:owner" = "kevin de notariis"
    "module:repo"  = "github.com/KevinDeNotariis/terraform-modules"
  }
}

# ---------------------------------------------------------------
# 1. Create a VPC
# ---------------------------------------------------------------
#tfsec:ignore:aws-ec2-require-vpc-flow-logs-for-all-vpcs
resource "aws_vpc" "this" {
  cidr_block          = var.vpc_cidr_block
  ipv4_ipam_pool_id   = var.ipam_pool_id
  ipv4_netmask_length = var.vpc_cidr_mask

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.tags, {
    Name = "${local.identifier}-${var.suffix}"
  })
}

# ---------------------------------------------------------------
# 2. Create an Internet Gateway
# ---------------------------------------------------------------
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.tags, {
    Name = "${local.identifier}-${var.suffix}"
  })
}

# ---------------------------------------------------------------
# 3. Create Route Table to the Internet Gateway
# ---------------------------------------------------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(local.tags, {
    Name = "${local.identifier}-public-${var.suffix}"
  })
}

# ---------------------------------------------------------------
# 4. Create the Subnets
# ---------------------------------------------------------------
resource "aws_subnet" "private" {
  for_each = local.az_private_subnets_map

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value
  map_public_ip_on_launch = false

  availability_zone = each.key

  tags = merge(local.tags, {
    Name = "${local.identifier}-private-${split("-", each.key)[2]}-${var.suffix}"
  })
}

resource "aws_subnet" "public" {
  for_each = local.az_public_subnets_map

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value
  map_public_ip_on_launch = false

  availability_zone = each.key

  tags = merge(local.tags, {
    Name = "${local.identifier}-public-${split("-", each.key)[2]}-${var.suffix}"
  })
}

# ---------------------------------------------------------------
# 5. Associate the public subnet to the route table
# ---------------------------------------------------------------
resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# ---------------------------------------------------------------
# 6. Create NAT gateways in the public subnets to allow
#    private instances to outbound on the internet.
# ---------------------------------------------------------------
resource "aws_eip" "nat_gateway" {
  for_each = { for name in local.availability_zones : name => name }

  vpc = true

  tags = merge(local.tags, {
    Name = "${local.identifier}-${split("-", each.key)[2]}-${var.suffix}"
  })
}

resource "aws_nat_gateway" "this" {
  for_each = aws_subnet.public

  connectivity_type = "public"
  subnet_id         = each.value.id
  allocation_id     = aws_eip.nat_gateway[each.key].id

  tags = merge(local.tags, {
    Name = "${local.identifier}-${var.suffix}"
  })
}

# ---------------------------------------------------------------
# 7. Create Route Tables for NAT gateways
# ---------------------------------------------------------------
resource "aws_route_table" "nat_gateway" {
  for_each = aws_subnet.public

  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this[each.key].id
  }

  tags = merge(local.tags, {
    Name = "${local.identifier}-private-${var.suffix}"
  })
}

# ---------------------------------------------------------------
# 8. Associate the NAT route table with the private subnet
# ---------------------------------------------------------------
resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.nat_gateway[each.key].id
}

# ---------------------------------------------------------------
# 9. Create a Private Hosted Zone Associated with the VPC
# ---------------------------------------------------------------
resource "aws_route53_zone" "this" {
  count = var.root_domain_name == null ? 0 : 1

  name = "${local.identifier}.${var.root_domain_name}"
  vpc {
    vpc_id = aws_vpc.this.id
  }

  tags = local.tags
}

output "vpc_id" {
  value = aws_vpc.this.id
}

output "vpc_cidr_block" {
  value = aws_vpc.this.cidr_block
}

output "internet_gateway_id" {
  value = aws_internet_gateway.this.id
}

output "public_route_table_id" {
  value = aws_route_table.public.id
}

output "private_subnets_ids" {
  value = [for subnet in aws_subnet.private : subnet.id]
}

output "private_subnets_cidr_blocks" {
  value = [for subnet in aws_subnet.private : subnet.cidr_block]
}

output "public_subnets_ids" {
  value = [for subnet in aws_subnet.public : subnet.id]
}

output "public_subnets_cidr_blocks" {
  value = [for subnet in aws_subnet.public : subnet.cidr_block]
}

output "private_hosted_zone_name" {
  value = var.root_domain_name != null ? aws_route53_zone.this[0].name : null
}

output "private_hosted_zone_id" {
  value = var.root_domain_name != null ? aws_route53_zone.this[0].id : null
}

output "lb_arn" {
  value = aws_lb.this.arn
}

output "lb_sg_id" {
  value = aws_security_group.this.id
}

output "lb_dns_name" {
  value = aws_lb.this.dns_name
}

output "lb_dns_cname" {
  value = aws_route53_record.this.name
}

output "lb_listener_arn" {
  value = aws_lb_listener.https.arn
}

output "lb_target_group_arn" {
  value = aws_lb_target_group.this.arn
}

output "lb_target_group_name" {
  value = aws_lb_target_group.this.name
}

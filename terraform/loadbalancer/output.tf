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
  value = var.lb_ignore_listeners_changes ? aws_lb_listener.https_with_ignore_changes[0].arn : aws_lb_listener.https[0].arn
}

output "lb_target_group_arn" {
  value = aws_lb_target_group.this.arn
}

output "lb_target_group_name" {
  value = aws_lb_target_group.this.name
}

output "lb_target_group_green_name" {
  value = var.enable_green_lb_target_group ? aws_lb_target_group.green[0].name : null
}

output "lb_target_group_green_arn" {
  value = var.enable_green_lb_target_group ? aws_lb_target_group.green[0].arn : null
}

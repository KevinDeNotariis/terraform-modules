output "autoscaling_policy_memory_arn" {
  value = aws_appautoscaling_policy.memory.arn
}

output "autoscaling_policy_memory_alarm_arns" {
  value = aws_appautoscaling_policy.memory.alarm_arns
}

output "autoscaling_policy_cpu_arn" {
  value = aws_appautoscaling_policy.cpu.arn
}

output "autoscaling_policy_cpu_alarm_arns" {
  value = aws_appautoscaling_policy.cpu.alarm_arns
}

output "ecr_repo_url" {
  value = aws_ecr_repository.this.repository_url
}

output "ecr_repo_name" {
  value = aws_ecr_repository.this.name
}

output "ecr_repo_arn" {
  value = aws_ecr_repository.this.arn
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.this.name
}

output "ecs_service_name" {
  value = aws_ecs_service.this.name
}

output "ecs_execution_role_arn" {
  value = aws_iam_role.ecs_execution.arn
}

output "ecs_execution_role_name" {
  value = aws_iam_role.ecs_execution.name
}

output "ecs_family" {
  value = aws_ecs_task_definition.this.family
}

output "ecs_cpu" {
  value = aws_ecs_task_definition.this.cpu
}

output "ecs_memory" {
  value = aws_ecs_task_definition.this.memory
}

output "ecs_network_mode" {
  value = aws_ecs_task_definition.this.network_mode
}

output "ecs_container_name" {
  value = local.ecs_container_name
}

output "ecs_container_log_group_name" {
  value = local.ecs_container_log_group_name
}

output "ecs_container_stream_prefix" {
  value = local.ecs_container_stream_prefix
}

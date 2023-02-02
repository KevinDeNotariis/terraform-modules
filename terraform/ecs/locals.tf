locals {
  identifier = "${var.identifier}-${var.environment}"

  dev_environments  = ["dev", "test"]
  prod_environments = ["stage", "prod"]

  tags = {
    "module:name"  = "ecs"
    "module:owner" = "kevin de notariis"
    "module:repo"  = "github.com/KevinDeNotariis/terraform-modules"
  }

  ecs_network_mode            = "awsvpc"
  ecs_container_name          = "${local.identifier}-${var.suffix}"
  ecs_container_stream_prefix = "ecs"
  ecs_container_log_group_name = format("%s/%s/%s/%s",
    local.identifier,
    "ecs",
    var.suffix,
    "task"
  )
}

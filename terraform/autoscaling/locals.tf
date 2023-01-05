locals {
  identifier = "${var.identifier}-${var.environment}"

  dev_environments  = ["dev", "test"]
  prod_environments = ["stage", "prod"]

  tags = {
    "module:name"  = "autoscaling"
    "module:owner" = "kevin de notariis"
    "module:repo"  = "github.com/KevinDeNotariis/terraform-modules"
  }
}

locals {
  identifier = "${var.identifier}-${var.environment}"
  lb_cname = try(
    "${var.lb_subdomain}.${var.root_domain_name}",
    "${local.identifier}.${var.root_domain_name}",
  )

  dev_environments  = ["dev", "test"]
  prod_environments = ["stage", "prod"]

  tags = {
    "module:name"  = "loadbalancer"
    "module:owner" = "kevin de notariis"
    "module:repo"  = "github.com/KevinDeNotariis/terraform-modules"
  }
}

locals {
  identifier = "${var.identifier}-${var.environment}"

  db_creds = jsondecode(data.aws_secretsmanager_secret_version.db_creds.secret_string)

  dev_environments  = ["dev", "test"]
  prod_environments = ["stage", "prod"]

  tags = {
    "module:name"  = "document-db"
    "module:owner" = "kevin de notariis"
    "module:repo"  = "github.com/KevinDeNotariis/terraform-modules"
  }
}

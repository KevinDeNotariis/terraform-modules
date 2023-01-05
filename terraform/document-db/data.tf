data "aws_availability_zones" "available" {}

data "aws_secretsmanager_secret_version" "db_creds" {
  secret_id = var.db_creds_secret_id
}

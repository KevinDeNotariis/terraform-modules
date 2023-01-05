# ---------------------------------------------------------------
# 1. Create the Subnet group where the DocumentDB cluster will
#    reside
# ---------------------------------------------------------------
resource "aws_docdb_subnet_group" "this" {
  name       = "${local.identifier}-${var.suffix}"
  subnet_ids = var.private_subnets_ids

  tags = local.tags
}

# ---------------------------------------------------------------
# 2. Create the Security groups for the DocumentDB instances
# ---------------------------------------------------------------
resource "aws_security_group" "this" {
  name   = "${local.identifier}-document-db-${var.suffix}"
  vpc_id = var.vpc_id

  ingress {
    description     = "Allow Inbound Port 27017 from EC2 in the autoscaling group"
    from_port       = 27017
    to_port         = 27017
    protocol        = "tcp"
    security_groups = [var.ag_ec2_sg_id]
  }

  egress {
    description     = "Allow Outbound Port 27017 to EC2 in the autoscaling group"
    from_port       = 27017
    to_port         = 27017
    protocol        = "tcp"
    security_groups = [var.ag_ec2_sg_id]
  }
}

# ---------------------------------------------------------------
# 3. Create the DocumentDB Cluster
# ---------------------------------------------------------------
resource "aws_docdb_cluster" "this" {
  cluster_identifier = "${local.identifier}-${var.suffix}"
  engine             = "docdb"
  storage_encrypted  = true

  backup_retention_period = contains(local.dev_environments, var.environment) ? 1 : 5
  preferred_backup_window = "03:00-05:00"

  db_subnet_group_name   = aws_docdb_subnet_group.this.name
  availability_zones     = data.aws_availability_zones.available.names
  vpc_security_group_ids = [aws_security_group.this.id]

  master_username = local.db_creds.username
  master_password = local.db_creds.password

  deletion_protection = contains(local.prod_environments, var.environment)
  skip_final_snapshot = contains(local.dev_environments, var.environment)
  apply_immediately   = contains(local.dev_environments, var.environment)

  tags = local.tags
}

# ---------------------------------------------------------------
# 4. Create the Document DB instances
# ---------------------------------------------------------------
resource "aws_docdb_cluster_instance" "this" {
  count                      = var.instance_count
  identifier                 = "${local.identifier}-${var.suffix}-${count.index}"
  cluster_identifier         = aws_docdb_cluster.this.id
  instance_class             = var.instance_class
  auto_minor_version_upgrade = true

  apply_immediately = contains(local.prod_environments, var.environment)

  tags = local.tags
}

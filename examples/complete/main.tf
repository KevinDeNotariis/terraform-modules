locals {
  identifier  = "my-app"
  environment = "test"
  suffix      = random_id.this.hex

  db_creds_secret_id = "my-secret-name"
  root_domain_name   = "myrootdomain.com"
}

resource "random_id" "this" {
  byte_length = 4
}

module "sns" {
  source = "../../terraform/sns"

  identifier  = local.identifier
  environment = local.environment
  suffix      = local.suffix

  sns_general_subscriptions = [{
    endpoint = "my_email@hello.world"
    protocol = "email"
  }]
}

module "network" {
  source = "../../terraform/network-simple"

  identifier  = local.identifier
  environment = local.environment
  suffix      = local.suffix

  vpc_cidr_block           = "10.0.0.0/24"
  private_subnets_new_bits = 3
  public_subnets_new_bits  = 3
}

module "loadbalancer" {
  source = "../../terraform/loadbalancer"

  identifier  = local.identifier
  environment = local.environment
  suffix      = local.suffix

  root_domain_name   = local.root_domain_name
  lb_cname_ttl       = 5
  vpc_id             = module.network.vpc_id
  vpc_cidr_block     = module.network.vpc_cidr_block
  public_subnets_ids = module.network.public_subnets_ids
}

module "ec2" {
  source = "../../terraform/ec2"
}

module "autoscaling" {
  source = "../../terraform/autoscaling"

  identifier  = local.identifier
  environment = local.environment
  suffix      = local.suffix

  user_data           = module.ec2.user_data
  lb_sg_id            = module.loadbalancer.lb_sg_id
  lb_target_group_arn = module.loadbalancer.lb_target_group_arn
  private_subnets_ids = module.network.private_subnets_ids
  vpc_id              = module.network.vpc_id
  vpc_cidr_block      = module.network.vpc_cidr_block
  db_creds_secret_id  = local.db_creds_secret_id
  asg_sns_arn         = module.sns.sns_general_arn
}

module "db" {
  source = "../../terraform/document-db"

  identifier  = local.identifier
  environment = local.environment
  suffix      = local.suffix

  db_creds_secret_id  = local.db_creds_secret_id
  ag_ec2_sg_id        = module.autoscaling.ag_ec2_sg_id
  private_subnets_ids = module.network.private_subnets_ids
  vpc_id              = module.network.vpc_id
}

module "codepipeline" {
  source = "../../terraform/codepipeline"

  identifier  = local.identifier
  environment = local.environment
  suffix      = local.suffix

  source_repo_id     = "mygithub/myrepo"
  source_branch_name = "main"

  deploy_server_config = {
    ag_id                = module.autoscaling.ag_id
    ag_ec2_iam_role_name = module.autoscaling.ag_ec2_iam_role_name
    lb_target_group_name = module.loadbalancer.lb_target_group_name
  }

  deploy_trigger_target_arn        = module.sns.sns_general_arn
  pipeline_notification_target_arn = module.sns.sns_general_arn
}

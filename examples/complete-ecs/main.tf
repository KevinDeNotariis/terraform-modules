locals {
  identifier  = "complete-ecs"
  environment = "test"
  suffix      = random_id.this.hex

  root_domain_name = "myrootdomain.com"
}

resource "random_id" "this" {
  byte_length = 4
}

module "sns" {
  source = "../../terraform/sns"

  identifier  = local.identifier
  environment = local.environment
  suffix      = local.suffix

  sns_general_subscriptions = [
    {
      protocol = "email"
      endpoint = "my-email@gmail.com"
    }
  ]
}

module "network" {
  source = "../../terraform/network-simple"

  identifier  = local.identifier
  environment = local.environment
  suffix      = local.suffix

  vpc_cidr_mask            = 24
  ipam_pool_id             = data.aws_vpc_ipam_pool.dev.id
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
  lb_target_type     = "ip"
}

module "ecs" {
  source = "../../terraform/ecs"

  identifier  = local.identifier
  environment = local.environment
  suffix      = local.suffix

  vpc_id                    = module.network.vpc_id
  vpc_cidr_block            = module.network.vpc_cidr_block
  private_subnets_ids       = module.network.private_subnets_ids
  lb_arn                    = module.loadbalancer.lb_arn
  lb_target_group_arn       = module.loadbalancer.lb_target_group_arn
  ecr_replication_region    = "eu-central-1"
  ecs_service_desired_count = 2
}

module "autoscaling_ecs" {
  source = "../../terraform/autoscaling-ecs"

  identifier  = local.identifier
  environment = local.environment
  suffix      = local.suffix

  min_capacity     = 2
  max_capacity     = 3
  ecs_cluster_name = module.ecs.ecs_cluster_name
  ecs_service_name = module.ecs.ecs_service_name
  scaling_sns_arn  = module.sns.sns_general_arn
}

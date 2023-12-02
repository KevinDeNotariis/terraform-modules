locals {
  identifier  = "complete-ecs"
  environment = "test"
  suffix      = random_id.this.hex

  root_domain_name = "mydomain.com"
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
      endpoint = "myemail@hello.com"
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

  root_domain_name             = local.root_domain_name
  lb_cname_ttl                 = 5
  vpc_id                       = module.network.vpc_id
  vpc_cidr_block               = module.network.vpc_cidr_block
  public_subnets_ids           = module.network.public_subnets_ids
  lb_target_type               = "ip"
  enable_green_lb_target_group = true
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

  depends_on = [
    module.network,
    module.loadbalancer
  ]
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

module "codepipeline" {
  source = "../../terraform/codepipeline"

  identifier  = local.identifier
  environment = local.environment
  suffix      = local.suffix

  vpc_id              = module.network.vpc_id
  private_subnets_ids = module.network.private_subnets_ids
  source_repo_id      = "me/my_repo"
  source_branch_name  = "main"

  deploy_platform = "ECS"
  deploy_ecs_config = {
    cluster_name               = module.ecs.ecs_cluster_name
    service_name               = module.ecs.ecs_service_name
    task_role_arn              = module.ecs.ecs_task_role_arn
    task_role_name             = module.ecs.ecs_task_role_name
    execution_role_arn         = module.ecs.ecs_execution_role_arn
    execution_role_name        = module.ecs.ecs_execution_role_name
    family                     = module.ecs.ecs_family
    network_mode               = module.ecs.ecs_network_mode
    memory                     = module.ecs.ecs_memory
    cpu                        = module.ecs.ecs_cpu
    lb_listener_arn            = module.loadbalancer.lb_listener_arn
    lb_target_group_blue_name  = module.loadbalancer.lb_target_group_name
    lb_target_group_green_name = module.loadbalancer.lb_target_group_green_name
    ecr_repo_arn               = module.ecs.ecr_repo_arn
    ecr_repo_name              = module.ecs.ecr_repo_name
    ecr_repo_url               = module.ecs.ecr_repo_url
    container_name             = module.ecs.ecs_container_name
    container_log_group_name   = module.ecs.ecs_container_log_group_name
    container_stream_prefix    = module.ecs.ecs_container_stream_prefix
  }

  deploy_trigger_target_arn        = module.sns.sns_general_arn
  pipeline_notification_target_arn = module.sns.sns_general_arn

  depends_on = [
    module.ecs,
  ]
}

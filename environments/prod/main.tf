locals {
  name_prefix = "todo-prod"
  common_tags = {
    Project     = "todo-api"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

module "vpc" {
  source = "../../modules/vpc"

  name_prefix        = local.name_prefix
  enable_nat_gateway = true # ECS tasks need outbound access to pull images from ECR
  tags               = local.common_tags
}

module "ecr" {
  source = "../../modules/ecr"

  repository_name = "todo-api-prod"
  tags            = local.common_tags
}

module "alb" {
  source = "../../modules/alb"

  name_prefix       = local.name_prefix
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  container_port    = 8000
  tags              = local.common_tags
}

module "ecs" {
  source = "../../modules/ecs"

  name_prefix        = local.name_prefix
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  alb_sg_id          = module.alb.alb_sg_id
  target_group_arn   = module.alb.target_group_arn
  container_port     = 8000
  image_url          = "${module.ecr.repository_url}:${var.image_tag}"
  desired_count      = var.desired_count
  db_secret_arn      = module.rds.secret_arn
  enable_autoscaling = var.enable_autoscaling
  min_capacity       = var.min_capacity
  max_capacity       = var.max_capacity
  tags               = local.common_tags
}

module "rds" {
  source = "../../modules/rds"

  name_prefix             = local.name_prefix
  vpc_id                  = module.vpc.vpc_id
  private_subnet_ids      = module.vpc.private_subnet_ids
  ecs_sg_id               = module.ecs.ecs_tasks_sg_id
  db_name                 = var.db_name
  master_username         = var.master_username
  multi_az                = var.multi_az
  deletion_protection     = var.deletion_protection
  backup_retention_period = var.backup_retention_period
  skip_final_snapshot     = var.skip_final_snapshot
  tags                    = local.common_tags
}

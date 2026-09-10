module "networking" {
  source = "../../modules/networking"

  project_name          = var.project_name
  environment           = var.environment
  vpc_cidr              = var.vpc_cidr
  azs                   = var.azs
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  single_nat_gateway    = true # dev: 1 NAT GW to save cost
}

module "security" {
  source = "../../modules/security"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.networking.vpc_id
  app_port     = var.app_port
  # ssh_allowed_cidrs left empty on purpose - use SSM Session Manager instead
}

module "storage" {
  source = "../../modules/storage"

  project_name  = var.project_name
  environment   = var.environment
  force_destroy = true # dev: ok to nuke bucket + its contents on destroy
}

module "compute" {
  source = "../../modules/compute"

  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.networking.vpc_id
  public_subnet_ids  = module.networking.public_subnet_ids
  private_subnet_ids = module.networking.private_subnet_ids
  alb_sg_id          = module.security.alb_sg_id
  ec2_sg_id          = module.security.ec2_sg_id

  instance_type    = var.instance_type
  app_port         = var.app_port
  docker_image     = var.docker_image
  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  aws_region            = var.aws_region
  app_data_bucket_arn   = module.storage.bucket_arn
  app_data_bucket_name  = module.storage.bucket_name
}

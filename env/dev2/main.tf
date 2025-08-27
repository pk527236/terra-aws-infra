# ENV/DEV/MAIN.TF
# ==============================================================================

module "iam" {
  source = "../../modules/iam"
  env    = var.env
  tags   = var.tags
}

module "vpc" {
  source          = "../../modules/vpc"
  env             = var.env
  vpc_cidr        = var.vpc_cidr
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
  azs             = var.azs
  tags            = var.tags
}

module "security_group" {
  source                 = "../../modules/security-group"
  env                    = var.env
  vpc_id                 = module.vpc.vpc_id
  vpc_cidr               = var.vpc_cidr
  ssh_cidr_blocks        = var.ssh_cidr_blocks
  monitoring_cidr_blocks = var.monitoring_cidr_blocks
  tags                   = var.tags
}

module "alb" {
  source          = "../../modules/alb"
  env             = var.env
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.public_subnets
  security_groups = [module.security_group.alb_security_group_id]
  tags            = var.tags
}

module "asg" {
  source                = "../../modules/asg"
  env                   = var.env
  instance_type         = var.instance_type
  key_name              = var.key_name
  ec2_security_group_id = module.security_group.ec2_security_group_id
  instance_profile_name = module.iam.ec2_instance_profile_name
  private_subnet_ids    = module.vpc.private_subnets
  min_size              = var.min_size
  max_size              = var.max_size
  desired_capacity      = var.desired_capacity
  target_group_arns     = [module.alb.target_group_arn]
  tags                  = var.tags
}
# module "monitoring" {
#   source                       = "../../modules/monitoring"
#   env                          = var.env
#   instance_type                = var.monitoring_instance_type
#   key_name                     = var.key_name
#   public_subnet_id             = module.vpc.public_subnets[0]
#   monitoring_security_group_id = module.security_group.monitoring_security_group_id
#   instance_profile_name        = module.iam.ec2_instance_profile_name
#   tags                         = var.tags

#   # Variables for templatefile in main.tf
#   prometheus_targets     = []              # list of strings for Prometheus targets
#   docker_compose_version = "2.21.0"        # Docker Compose version
#   asg_name               = "dev-web-asg"   # must match ASG created by asg module
#   aws_region             = var.region      # pass region (lowercase to match variable name)
# }

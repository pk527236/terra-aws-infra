provider "aws" {
  region = var.region
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
  source = "../../modules/alb"
  alb_name            = var.alb_name
  alb_port            = var.alb_port
  alb_protocol        = var.alb_protocol
  vpc_id              = module.vpc.vpc_id
  public_subnets      = module.vpc.public_subnets
  asg_target_group_arn = module.asg.target_group_arn
}

module "asg" {
  source            = "../../modules/asg"
  project           = var.project
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.private_subnet_ids
  instance_type     = var.instance_type
  ami_id            = var.ami_id
  key_name          = var.key_name
  user_data         = file("${path.module}/../scripts/user-data.sh")
  security_groups   = [module.sg.app_sg_id]
  target_group_arns = [module.alb.target_group_arn]
}

# ENV/DEV/OUTPUTS.TF
# ==============================================================================

# VPC Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = var.vpc_cidr
}

output "public_subnets" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnets
}

# ALB Outputs
output "alb_dns_name" {
  description = "DNS name of the load balancer"
  value       = module.alb.alb_dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the load balancer"
  value       = module.alb.alb_zone_id
}

output "alb_arn" {
  description = "ARN of the load balancer"
  value       = module.alb.alb_arn
}

# ASG Outputs
output "asg_name" {
  description = "Auto Scaling Group name"
  value       = module.asg.asg_name
}

output "asg_arn" {
  description = "Auto Scaling Group ARN"
  value       = module.asg.asg_arn
}

# Security Group Outputs
output "alb_security_group_id" {
  description = "ALB Security Group ID"
  value       = module.security_group.alb_security_group_id
}

output "ec2_security_group_id" {
  description = "EC2 Security Group ID"
  value       = module.security_group.ec2_security_group_id
}

output "monitoring_security_group_id" {
  description = "Monitoring Security Group ID"
  value       = module.security_group.monitoring_security_group_id
}

# URLs for easy access
output "website_urls" {
  description = "URLs to access the websites"
  value = {
    alb_default = "http://${module.alb.alb_dns_name}/"
    health_check = "http://${module.alb.alb_dns_name}/health"
    test1_site = "http://${module.alb.alb_dns_name}/" # Will work with Host header
    test2_site = "http://${module.alb.alb_dns_name}/" # Will work with Host header
  }
}

# Instructions for testing
output "testing_instructions" {
  description = "Commands to test the setup"
  value = {
    default_site = "curl -v http://${module.alb.alb_dns_name}/"
    health_check = "curl -v http://${module.alb.alb_dns_name}/health"
    test1_with_host = "curl -v -H 'Host: test1.exclcloud.com' http://${module.alb.alb_dns_name}/"
    test2_with_host = "curl -v -H 'Host: test2.exclcloud.com' http://${module.alb.alb_dns_name}/"
  }
}
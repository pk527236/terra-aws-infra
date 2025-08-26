output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnets" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnets
}

output "nat_gateway_id" {
  description = "NAT Gateway ID"
  value       = try(module.vpc.nat_gateway_id, "")
}

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

output "asg_name" {
  description = "Auto Scaling Group name"
  value       = module.autoscaling.asg_name
}

output "launch_template_id" {
  description = "Launch Template ID"
  value       = module.autoscaling.launch_template_id
}
output "alb_dns_name" {
  value = module.alb.alb_dns_name
}
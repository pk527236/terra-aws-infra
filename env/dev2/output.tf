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
  value       = module.vpc.nat_gateway_id
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

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.alb_dns_name
}

output "asg_name" {
  description = "Auto Scaling Group name"
  value       = module.asg.asg_name
}

output "launch_template_id" {
  description = "Launch Template ID"
  value       = module.asg.launch_template_id
}

# Monitoring outputs
# output "monitoring_instance_id" {
#   description = "Monitoring server instance ID"
#   value       = module.monitoring.monitoring_instance_id
# }

# output "monitoring_public_ip" {
#   description = "Monitoring server public IP"
#   value       = module.monitoring.monitoring_public_ip
# }

# output "prometheus_url" {
#   description = "Prometheus dashboard URL"
#   value       = "http://${module.monitoring.monitoring_public_ip}:9090"
# }

# output "grafana_url" {
#   description = "Grafana dashboard URL"
#   value       = "http://${module.monitoring.monitoring_public_ip}:3000"
# }

# output "alertmanager_url" {
#   description = "Alertmanager URL"
#   value       = "http://${module.monitoring.monitoring_public_ip}:9093"
# }

# output "jenkins_url" {
#   description = "Jenkins URL"
#   value       = "http://${module.monitoring.monitoring_public_ip}:8080"
# }
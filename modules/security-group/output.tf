# modules/security-group/outputs.tf

output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "ec2_security_group_id" {
  description = "ID of the EC2 security group"
  value       = aws_security_group.ec2.id
}

output "monitoring_security_group_id" {
  description = "ID of the monitoring security group"
  value       = aws_security_group.monitoring.id
}
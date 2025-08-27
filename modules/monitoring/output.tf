# MODULES/MONITORING/OUTPUTS.TF
# ==============================================================================

output "monitoring_instance_id" {
  description = "ID of the monitoring instance"
  value       = aws_instance.monitoring.id
}

output "monitoring_public_ip" {
  description = "Public IP of the monitoring instance"
  value       = aws_instance.monitoring.public_ip
}

output "monitoring_private_ip" {
  description = "Private IP of the monitoring instance"
  value       = aws_instance.monitoring.private_ip
}
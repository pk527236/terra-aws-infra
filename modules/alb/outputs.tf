# MODULES/ALB/OUTPUTS.TF
# ==============================================================================

output "alb_arn" {
  description = "ARN of the load balancer"
  value       = aws_lb.this.arn
}

output "alb_dns_name" {
  description = "DNS name of the load balancer"
  value       = aws_lb.this.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the load balancer"
  value       = aws_lb.this.zone_id
}

output "main_target_group_arn" {
  description = "ARN of the main target group"
  value       = aws_lb_target_group.main.arn
}

output "test1_target_group_arn" {
  description = "ARN of the test1 target group"
  value       = aws_lb_target_group.test1.arn
}

output "test2_target_group_arn" {
  description = "ARN of the test2 target group"
  value       = aws_lb_target_group.test2.arn
}

output "all_target_group_arns" {
  description = "List of all target group ARNs"
  value       = [
    aws_lb_target_group.main.arn,
    aws_lb_target_group.test1.arn,
    aws_lb_target_group.test2.arn
  ]
}

output "http_listener_arn" {
  description = "ARN of the HTTP listener"
  value       = aws_lb_listener.http.arn
}

output "https_listener_arn" {
  description = "ARN of the HTTPS listener"
  value       = var.enable_https ? aws_lb_listener.https[0].arn : null
}
# MODULES/MONITORING/VARIABLES.TF
# ==============================================================================

variable "env" {
  description = "Environment name"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "key_name" {
  description = "AWS Key Pair name"
  type        = string
}

variable "public_subnet_id" {
  description = "Public subnet ID for monitoring instance"
  type        = string
}

variable "monitoring_security_group_id" {
  description = "Security group ID for monitoring"
  type        = string
}

variable "instance_profile_name" {
  description = "IAM instance profile name"
  type        = string
}

variable "prometheus_targets" {
  description = "List of targets for Prometheus scraping"
  type        = list(string)
  default     = []
}
variable "docker_compose_version" {
  description = "Version of Docker Compose to install"
  type        = string
  default     = "2.21.0"
}
variable "asg_name" {
  description = "Name of Auto Scaling Group for Jenkins deployment"
  type        = string
}
variable "aws_region" {
  type        = string
  description = "AWS region for the deployment"
}
variable "tags" {
  description = "Common tags to be applied to all resources"
  type        = map(string)
  default     = {}
}

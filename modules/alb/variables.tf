# ==============================================================================
# MODULES/ALB/VARIABLES.TF
# ==============================================================================

variable "env" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where ALB will be created"
  type        = string
}

variable "subnet_ids" {
  description = "Subnets for ALB"
  type        = list(string)
}

variable "security_groups" {
  description = "Security groups for ALB"
  type        = list(string)
}

variable "tags" {
  description = "Common tags to be applied to all resources"
  type        = map(string)
  default     = {}
}
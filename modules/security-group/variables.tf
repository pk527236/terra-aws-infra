# modules/security-group/variables.tf

variable "env" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where security groups will be created"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC"
  type        = string
}

variable "ssh_cidr_blocks" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Restrict this in production
}

variable "monitoring_cidr_blocks" {
  description = "CIDR blocks allowed for monitoring services"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Restrict this in production
}

variable "tags" {
  description = "Common tags to be applied to all resources"
  type        = map(string)
  default     = {}
}
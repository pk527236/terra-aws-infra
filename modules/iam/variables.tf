# MODULES/IAM/VARIABLES.TF
# ==============================================================================

variable "env" {
  description = "Environment name"
  type        = string
}

variable "tags" {
  description = "Common tags to be applied to all resources"
  type        = map(string)
  default     = {}
}
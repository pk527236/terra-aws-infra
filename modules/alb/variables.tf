variable "project" {}
variable "vpc_id" {}
variable "subnet_ids" {
  type = list(string)
}
variable "security_groups" {
  type = list(string)
}
variable "target_group_arns" {
  type    = list(string)
  default = []
}
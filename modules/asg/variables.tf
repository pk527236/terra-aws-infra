variable "env" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "key_name" {
  type = string
}

variable "ec2_security_group_id" {
  type = string
  description = "EC2 security group id (single id). Will be passed into vpc_security_group_ids."
}

variable "private_subnet_ids" {
  type = list(string)
  description = "List of private subnet IDs for ASG"
}

variable "min_size" {
  type    = number
  default = 2
}

variable "max_size" {
  type    = number
  default = 2
}

variable "desired_capacity" {
  type    = number
  default = 2
}

variable "tags" {
  type    = map(string)
  default = {}
}
variable "target_group_arns" {
  type    = list(string)
  default = []
}
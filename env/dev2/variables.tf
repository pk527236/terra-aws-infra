variable "env" {
  type = string
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "vpc_cidr" {
  type = string
}

variable "public_subnets" {
  type = list(string)
}

variable "private_subnets" {
  type = list(string)
}

variable "azs" {
  type = list(string)
}

variable "tags" {
  type = map(string)
}

variable "ssh_cidr_blocks" {
  type = list(string)
  default = ["0.0.0.0/0"]
}

variable "monitoring_cidr_blocks" {
  type = list(string)
  default = ["0.0.0.0/0"]
}

variable "key_name" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
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

variable "alb_name" {
  description = "Name of the Application Load Balancer"
  type        = string
}

variable "alb_port" {
  description = "Port on which ALB listens"
  type        = number
  default     = 80
}

variable "alb_protocol" {
  description = "Protocol used by ALB"
  type        = string
  default     = "HTTP"
}
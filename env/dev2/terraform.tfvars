env             = "dev"
region          = "us-east-1"
vpc_cidr        = "10.0.0.0/16"
public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]
azs             = ["us-east-1a", "us-east-1b"]
tags = {
  Project = "Assignment"
  Owner   = "Piyush"
}


ssh_cidr_blocks        = ["0.0.0.0/0"]   # Replace with your own IP for prod
monitoring_cidr_blocks = ["0.0.0.0/0"]   # Restrict access to Prometheus, Grafana, Jenkins

# EC2 / ASG
key_name        = "shell-script"    # replace with your key pair name
instance_type   = "t2.micro"
min_size        = 2
max_size        = 2
desired_capacity= 2

alb_name     = "dev-app-alb"
alb_port     = 80
alb_protocol = "HTTP"
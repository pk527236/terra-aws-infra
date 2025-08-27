# ENV/DEV/TERRAFORM.TFVARS
# ==============================================================================

env             = "dev"
region          = "us-east-1"
vpc_cidr        = "10.0.0.0/16"
public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]
azs             = ["us-east-1a", "us-east-1b"]

tags = {
  Project     = "Assignment"
  Owner       = "Piyush"
  Environment = "dev"
}

# Security - Update these with your actual IP ranges for production
ssh_cidr_blocks        = ["0.0.0.0/0"]   # Replace with your IP for production
monitoring_cidr_blocks = ["0.0.0.0/0"]   # Restrict access for production

# EC2 Configuration
key_name         = "shell-script"    # Replace with your key pair name
instance_type    = "t2.micro"
min_size         = 2
max_size         = 2
desired_capacity = 2
# monitoring_instance_type = "t3.medium"

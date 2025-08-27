data "aws_ami" "ubuntu_monitoring" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "monitoring" {
  ami                    = data.aws_ami.ubuntu_monitoring.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [var.monitoring_security_group_id]
  iam_instance_profile   = var.instance_profile_name

  user_data = base64encode(templatefile("${path.module}/scripts/monitoring-stack.sh", {
  prometheus_targets     = join(",", var.prometheus_targets)
  DOCKER_COMPOSE_VERSION = var.docker_compose_version
  ASG_NAME               = var.asg_name
  AWS_REGION             = var.aws_region
  env                    = var.env
}))

  tags = merge(var.tags, {
    Name = "${var.env}-monitoring-server"
    Type = "Monitoring"
  })
}

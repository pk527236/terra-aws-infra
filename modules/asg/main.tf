data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

resource "aws_launch_template" "web" {
  name_prefix   = "${var.env}-web-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = var.key_name

  user_data = base64encode(
    templatefile("${path.module}/scripts/user-data.tpl", {
      nginx      = file("${path.module}/scripts/nginx-setup.sh"),
      monitoring = file("${path.module}/scripts/monitoring-setup.sh")
    })
  )

  vpc_security_group_ids = [var.ec2_security_group_id]

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name = "${var.env}-web-instance"
    })
  }
}

resource "aws_autoscaling_group" "web" {
  name                 = "${var.env}-web-asg"
  target_group_arns = var.target_group_arns
  min_size             = var.min_size
  max_size             = var.max_size
  desired_capacity     = var.desired_capacity
  vpc_zone_identifier  = var.private_subnet_ids
  health_check_type    = "EC2"
  force_delete         = true

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.env}-web-instance"
    propagate_at_launch = true
  }
}

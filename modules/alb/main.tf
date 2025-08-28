# MODULES/ALB/MAIN.TF
# ==============================================================================

resource "aws_lb" "this" {
  name               = "${var.env}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = var.security_groups
  subnets            = var.subnet_ids
  enable_deletion_protection = false

  tags = merge(var.tags, {
    Name = "${var.env}-alb"
  })
}

# Main target group for health checks and default traffic
resource "aws_lb_target_group" "main" {
  name     = "${var.env}-main-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"  # Changed to use specific health endpoint
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 3  # Increased to avoid frequent cycling
  }

  tags = merge(var.tags, {
    Name = "${var.env}-main-tg"
  })
}

# Target group for test1.exclcloud.com
resource "aws_lb_target_group" "test1" {
  name     = "${var.env}-test1-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 3
  }

  tags = merge(var.tags, {
    Name = "${var.env}-test1-tg"
  })
}

# Target group for test2.exclcloud.com
resource "aws_lb_target_group" "test2" {
  name     = "${var.env}-test2-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 3
  }

  tags = merge(var.tags, {
    Name = "${var.env}-test2-tg"
  })
}

# HTTP Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = "80"
  protocol          = "HTTP"

  # Default action - forward to main target group
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

# HTTP Listener Rules for host-based routing
resource "aws_lb_listener_rule" "test1" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.test1.arn
  }

  condition {
    host_header {
      values = ["test1.exclcloud.com"]
    }
  }
}

resource "aws_lb_listener_rule" "test2" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 200

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.test2.arn
  }

  condition {
    host_header {
      values = ["test2.exclcloud.com"]
    }
  }
}

# HTTPS Listener (optional, for SSL termination at ALB)
resource "aws_lb_listener" "https" {
  count = var.enable_https ? 1 : 0
  
  load_balancer_arn = aws_lb.this.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

resource "aws_lb_listener_rule" "test1_https" {
  count = var.enable_https ? 1 : 0
  
  listener_arn = aws_lb_listener.https[0].arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.test1.arn
  }

  condition {
    host_header {
      values = ["test1.exclcloud.com"]
    }
  }
}

resource "aws_lb_listener_rule" "test2_https" {
  count = var.enable_https ? 1 : 0
  
  listener_arn = aws_lb_listener.https[0].arn
  priority     = 200

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.test2.arn
  }

  condition {
    host_header {
      values = ["test2.exclcloud.com"]
    }
  }
}
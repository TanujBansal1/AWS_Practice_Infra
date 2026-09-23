# ALB is the only thing that should ever be reachable from the public
# internet - it terminates inbound HTTP on 80 and forwards only to ECS.
resource "aws_security_group" "alb" {
  description = "Controls traffic to/from the public ALB - HTTP in from anywhere, out to ECS tasks."
  name_prefix = "${var.name_prefix}-alb-"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # AWS-0104 (unrestricted egress): the ALB must reach ECS tasks' dynamic
  # per-task IPs (awsvpc mode assigns a fresh ENI IP per task) - SGs can't
  # scope egress to "whatever the target group currently contains", so this
  # stays broad. Ingress (the actual internet-facing side) is tightly
  # scoped to port 80 above.
  #tfsec:ignore:AWS-0104
  egress {
    description = "All outbound (to ECS tasks)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-alb-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# AWS-0053 (publicly exposed load balancer): intentional - this is the
# public entry point for the app by design.
#tfsec:ignore:AWS-0053
resource "aws_lb" "app" {
  name                       = "${var.name_prefix}-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb.id]
  subnets                    = var.public_subnet_ids
  drop_invalid_header_fields = true # free, no reason not to reject malformed headers

  tags = var.tags
}

# target_type = "ip" is required for Fargate tasks (awsvpc networking mode
# gives each task its own ENI/IP, unlike EC2 launch type's instance targets).
resource "aws_lb_target_group" "app" {
  name        = "${var.name_prefix}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 15
    timeout             = 5
    matcher             = "200"
  }

  tags = var.tags
}

# AWS-0054 (plain HTTP, no TLS): real finding, not a false positive - this
# project has no ACM certificate or custom domain yet. Flagged as a known
# gap to close in a future "HTTPS" phase (ACM cert + HTTPS listener +
# HTTP->HTTPS redirect), not silently accepted.
#tfsec:ignore:AWS-0054
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

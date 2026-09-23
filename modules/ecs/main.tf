# AWS-0034 (Container Insights): adds recurring CloudWatch cost for
# per-task/service metrics beyond what's already logged - not justified for
# a learning project's traffic volume.
#tfsec:ignore:AWS-0034
resource "aws_ecs_cluster" "main" {
  name = "${var.name_prefix}-cluster"
  tags = var.tags
}

# AWS-0017 (customer-managed KMS key): same cost/complexity tradeoff as
# elsewhere in this project - AWS-managed encryption is already on by
# default for CloudWatch Logs.
#tfsec:ignore:AWS-0017
resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${var.name_prefix}"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

# The execution role is used by the ECS agent itself (not app code) to pull
# the image from ECR and ship container logs to CloudWatch.
resource "aws_iam_role" "execution" {
  name = "${var.name_prefix}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "execution_managed" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# The task definition's "secrets" block is resolved by the ECS agent using
# the EXECUTION role (not the task role) at container startup - this is
# what actually lets the "secrets" injection below work. Scoped to the one
# specific secret ARN, not "*".
resource "aws_iam_role_policy" "execution_secrets" {
  name = "${var.name_prefix}-execution-secrets"
  role = aws_iam_role.execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "secretsmanager:GetSecretValue"
      Resource = var.db_secret_arn
    }]
  })
}

# The task role is assumed by the application code itself at runtime (AWS
# SDK calls from within the container). Left with no permissions for now -
# least privilege until the app actually needs to call an AWS API.
resource "aws_iam_role" "task" {
  name = "${var.name_prefix}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_ecs_task_definition" "app" {
  family                   = "${var.name_prefix}-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn

  container_definitions = jsonencode([
    {
      name      = "app"
      image     = var.image_url
      essential = true
      portMappings = [
        {
          containerPort = var.container_port
          protocol      = "tcp"
        }
      ]
      environment = [
        for k, v in var.environment_variables : { name = k, value = v }
      ]
      # Pulled from Secrets Manager at container start, not baked into the
      # task definition as plaintext - the ":key::" suffix selects a single
      # JSON key out of the secret.
      secrets = [
        { name = "DB_HOST", valueFrom = "${var.db_secret_arn}:host::" },
        { name = "DB_PORT", valueFrom = "${var.db_secret_arn}:port::" },
        { name = "DB_NAME", valueFrom = "${var.db_secret_arn}:dbname::" },
        { name = "DB_USER", valueFrom = "${var.db_secret_arn}:username::" },
        { name = "DB_PASSWORD", valueFrom = "${var.db_secret_arn}:password::" },
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.app.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "app"
        }
      }
    }
  ])

  tags = var.tags
}

data "aws_region" "current" {}

# Only the ALB may reach ECS tasks, and only on the app port - referencing
# the ALB's security group ID (not a CIDR) means this rule tracks the ALB
# automatically even if its IPs change.
resource "aws_security_group" "ecs_tasks" {
  description = "Controls traffic to/from ECS tasks - app port in from ALB only, out to ECR/NAT/RDS."
  name_prefix = "${var.name_prefix}-ecs-tasks-"
  vpc_id      = var.vpc_id

  ingress {
    description     = "App port from ALB only"
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [var.alb_sg_id]
  }

  # AWS-0104 (unrestricted egress): tasks need to reach ECR/CloudWatch/STS
  # via NAT (all dynamic AWS-managed public IPs, not scopable via SG) plus
  # RDS - narrowing this would require AWS-managed prefix lists, out of
  # scope for this phase. Ingress (the real attack surface) is tightly
  # scoped to the ALB's SG above.
  #tfsec:ignore:AWS-0104
  egress {
    description = "All outbound (ECR image pull via NAT, RDS access)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-ecs-tasks-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Terraform's `lifecycle` arguments must be static - `ignore_changes` can't
# be conditioned on a variable. Once autoscaling owns desired_count, every
# apply must ignore it or Terraform will fight the autoscaler back down to
# var.desired_count. So this is two resources gated by count, not one
# resource with a conditional lifecycle block - the standard workaround for
# this specific Terraform limitation.

resource "aws_ecs_service" "app" {
  count = var.enable_autoscaling ? 0 : 1

  name            = "${var.name_prefix}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [aws_security_group.ecs_tasks.id]
    # No public IP: tasks live in private subnets and are only reachable via
    # the ALB.
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "app"
    container_port   = var.container_port
  }

  tags = var.tags
}

resource "aws_ecs_service" "app_autoscaled" {
  count = var.enable_autoscaling ? 1 : 0

  name            = "${var.name_prefix}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "app"
    container_port   = var.container_port
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [desired_count]
  }
}

locals {
  ecs_service_name = var.enable_autoscaling ? aws_ecs_service.app_autoscaled[0].name : aws_ecs_service.app[0].name
}

resource "aws_appautoscaling_target" "ecs" {
  count = var.enable_autoscaling ? 1 : 0

  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${aws_ecs_cluster.main.name}/${local.ecs_service_name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  depends_on = [aws_ecs_service.app_autoscaled]
}

# Target tracking on CPU 70% - scales tasks up/down to keep average CPU near
# this target, between min_capacity and max_capacity.
resource "aws_appautoscaling_policy" "cpu" {
  count = var.enable_autoscaling ? 1 : 0

  name               = "${var.name_prefix}-cpu-target-tracking"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 70
  }
}

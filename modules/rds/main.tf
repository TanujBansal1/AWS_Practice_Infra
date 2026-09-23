# Generated once and stored only in Secrets Manager + Terraform state - never
# typed by a human, never committed to a .tf file.
resource "random_password" "master" {
  length  = 24
  special = false # avoid characters that need escaping in connection strings / JSON
}

resource "aws_db_subnet_group" "main" {
  name       = "${var.name_prefix}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-db-subnet-group"
  })
}

# Only the ECS tasks may reach the database, and only on 5432 - referencing
# the ECS security group ID (not a CIDR), same SG-chaining pattern as
# ALB -> ECS.
resource "aws_security_group" "rds" {
  description = "Controls traffic to the RDS instance - Postgres in from ECS tasks only, no egress needed."
  name_prefix = "${var.name_prefix}-rds-"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Postgres from ECS tasks only"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.ecs_sg_id]
  }

  # No egress block at all: Postgres doesn't initiate outbound connections,
  # so (unlike the ALB/ECS security groups) this can be genuinely
  # deny-all-egress rather than an accepted-risk broad rule - fixes
  # AWS-0104 for real instead of just justifying it.

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-rds-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# AWS-0176 (IAM database authentication disabled): would replace the
# Secrets Manager password entirely with short-lived IAM tokens - a bigger
# app-level change (app code + task role permissions) than this phase's
# scope, flagged as a future improvement rather than silently skipped.
# AWS-0078 (Performance Insights CMK): same cost/complexity tradeoff as
# other CMK findings in this project - AWS-managed encryption by default.
#tfsec:ignore:AWS-0176
#tfsec:ignore:AWS-0078
resource "aws_db_instance" "main" {
  identifier     = "${var.name_prefix}-db"
  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage = var.allocated_storage
  storage_encrypted = true # state can contain sensitive todo data eventually - encrypt at rest

  db_name  = var.db_name
  username = var.master_username
  password = random_password.master.result

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false # private subnets only - never reachable from the internet
  multi_az               = var.multi_az
  deletion_protection    = var.deletion_protection

  performance_insights_enabled = true # free with the default 7-day retention - no reason not to

  backup_retention_period = var.backup_retention_period
  skip_final_snapshot     = var.skip_final_snapshot

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-db"
  })
}

# Credentials live here, not in Terraform variables or plain env vars - ECS
# reads them at container start via the task definition's "secrets" block.
# AWS-0098 (customer-managed KMS key): same cost/complexity tradeoff as
# elsewhere in this project - AWS-managed encryption is already on by
# default for Secrets Manager.
#tfsec:ignore:AWS-0098
resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "${var.name_prefix}/db-credentials"
  recovery_window_in_days = 0 # dev convenience: allows immediate re-creation instead of AWS's default 30-day soft-delete hold. Not appropriate for prod.
  tags                    = var.tags
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    host     = aws_db_instance.main.address
    port     = tostring(aws_db_instance.main.port)
    dbname   = var.db_name
    username = var.master_username
    password = random_password.master.result
  })
}

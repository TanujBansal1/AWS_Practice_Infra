# modules/rds

Reusable Terraform module for RDS PostgreSQL.

Provisions the database in a private subnet with a dedicated security group,
with credentials sourced from AWS Secrets Manager (never hardcoded).

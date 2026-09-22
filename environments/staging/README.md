# environments/staging

Root Terraform config for the staging environment.

Calls the shared modules (vpc, alb, ecs, rds) with staging-sized variables and
maintains its own remote state file.

# environments/prod

Root Terraform config for the prod environment.

Calls the shared modules (vpc, alb, ecs, rds) with prod-sized variables and
maintains its own remote state file.

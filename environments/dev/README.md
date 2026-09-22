# environments/dev

Root Terraform config for the dev environment.

Calls the shared modules (vpc, alb, ecs, rds) with dev-sized variables and
maintains its own remote state file.

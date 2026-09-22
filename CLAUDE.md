# Project: AWS Infrastructure with Terraform & CI/CD

## Goal
Learning project to gain PRACTICAL DevOps skills for interviews.
Focus is on infrastructure, not application complexity.

## Tech Stack
- IaC: Terraform (latest)
- Cloud: AWS (free tier where possible)
- Container: Docker + ECS Fargate
- Database: RDS PostgreSQL
- CI/CD: GitHub Actions with OIDC (no long-lived keys)
- App: Simple Todo REST API (Python FastAPI)

## Rules for Claude
- ALWAYS explain WHY a resource/decision is made (I'm learning)
- Use Terraform modules and multi-environment structure
- Follow least-privilege IAM
- Never hardcode secrets - use AWS Secrets Manager
- Add comments in Terraform explaining non-obvious choices
- Prioritize free-tier eligible resources
- Warn me about anything that costs money
- Use remote state (S3 + DynamoDB locking)

## Architecture
VPC (2 AZ) -> ALB -> ECS Fargate -> RDS PostgreSQL (private)
Supporting: ECR, Secrets Manager, CloudWatch, IAM, NAT Gateway

## Folder Structure
- /modules (vpc, ecs, rds, alb)
- /environments (dev, staging, prod)
- /app (application code)
- /.github/workflows (CI/CD pipelines)

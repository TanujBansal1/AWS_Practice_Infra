# Copilot Instructions
Project: AWS Terraform + ECS Fargate + GitHub Actions CI/CD (learning project).
- Remote state: S3 bucket "tanay-tf-state-phase-one" + DynamoDB "terraform-locks"
- Region: us-east-1
- Auth: GitHub OIDC (NO stored AWS access keys)
- App: FastAPI Todo on ECS Fargate, image in ECR
- Rules: explain the "why", flag AWS cost implications, least-privilege IAM,
  never hardcode secrets, use git-sha image tags.
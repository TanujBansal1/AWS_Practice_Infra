# scan_on_push catches known CVEs in pushed images for free - worth having
# on by default even for a learning project.
# AWS-0031 (mutable image tags): flagging rather than blindly "fixing" -
# every deploy in this project's documented workflow re-pushes the same
# ":latest" tag (see environments/*/variables.tf image_tag). Switching to
# IMMUTABLE would break that workflow on the second deploy; the real fix is
# moving to per-build tags (git SHA / build number), which is a deploy
# workflow change out of scope for this phase, not a one-line toggle here.
# AWS-0033 (customer-managed KMS key): same cost/complexity tradeoff as the
# state bucket - AWS-managed encryption is already on by default.
#tfsec:ignore:AWS-0031
#tfsec:ignore:AWS-0033
resource "aws_ecr_repository" "app" {
  name = var.repository_name

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = var.tags
}

# Without a lifecycle policy, every pushed image (including CI test builds)
# accumulates forever and slowly adds storage cost. Keep only the last 5.
resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 5 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 5
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

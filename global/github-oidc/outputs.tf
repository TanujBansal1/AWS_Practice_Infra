output "role_arn" {
  description = "IAM role ARN to configure in GitHub Actions for OIDC deployment."
  value       = aws_iam_role.github_actions.arn
}
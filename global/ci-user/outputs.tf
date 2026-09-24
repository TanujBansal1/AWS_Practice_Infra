output "access_key_id" {
  description = "Access key ID for the GitHub Actions CI user."
  value       = aws_iam_access_key.github_actions_ci.id
  sensitive   = true
}

output "secret_access_key" {
  description = "Secret access key for the GitHub Actions CI user."
  value       = aws_iam_access_key.github_actions_ci.secret
  sensitive   = true
}
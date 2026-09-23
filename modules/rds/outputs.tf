output "secret_arn" {
  description = "ARN of the Secrets Manager secret holding DB credentials - grant ECS's execution role read access to this and reference it in the task definition's secrets block."
  value       = aws_secretsmanager_secret.db_credentials.arn
}

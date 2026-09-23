output "repository_url" {
  description = "URI to push/pull images (used in docker push and the ECS task definition)."
  value       = aws_ecr_repository.app.repository_url
}

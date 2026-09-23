output "alb_dns_name" {
  description = "Public URL to reach the app (http://<this>/health, /todos)."
  value       = module.alb.alb_dns_name
}

output "ecr_repository_url" {
  description = "Push images here before running terraform apply / re-deploying."
  value       = module.ecr.repository_url
}

output "db_secret_arn" {
  description = "ARN of the Secrets Manager secret holding DB credentials (ARN only, not the password itself)."
  value       = module.rds.secret_arn
}

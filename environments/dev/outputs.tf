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

output "frontend_url" {
  description = "Public HTTPS URL of the deployed frontend."
  value       = module.frontend.frontend_url
}

output "frontend_bucket_name" {
  description = "S3 bucket to sync frontend files to before invalidating CloudFront."
  value       = module.frontend.bucket_name
}

output "frontend_cloudfront_distribution_id" {
  description = "CloudFront distribution ID - invalidate this after syncing new frontend files."
  value       = module.frontend.cloudfront_distribution_id
}

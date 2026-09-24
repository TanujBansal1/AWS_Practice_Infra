output "bucket_name" {
  description = "Name of the S3 bucket holding the static frontend files - sync build output here."
  value       = aws_s3_bucket.frontend.bucket
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID - needed to invalidate the cache after each deploy."
  value       = aws_cloudfront_distribution.frontend.id
}

output "cloudfront_domain_name" {
  description = "CloudFront default domain (e.g. d123abc.cloudfront.net)."
  value       = aws_cloudfront_distribution.frontend.domain_name
}

output "frontend_url" {
  description = "Public HTTPS URL of the deployed frontend."
  value       = "https://${aws_cloudfront_distribution.frontend.domain_name}"
}

output "bucket_name" {
  description = "S3 bucket name to reference in each environment's backend \"s3\" block."
  value       = aws_s3_bucket.terraform_state.bucket
}

output "dynamodb_table_name" {
  description = "DynamoDB table name to reference as dynamodb_table in each environment's backend \"s3\" block."
  value       = aws_dynamodb_table.terraform_locks.name
}

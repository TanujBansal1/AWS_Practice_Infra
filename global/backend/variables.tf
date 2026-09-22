variable "bucket_name" {
  description = "Globally-unique S3 bucket name for storing Terraform remote state. No default: bucket names are unique across ALL of AWS, so this must be chosen deliberately (e.g. include account id or a random suffix)."
  type        = string
}

variable "aws_region" {
  description = "AWS region to create the state bucket and DynamoDB lock table in. Defaults to us-east-1, which has the broadest free-tier service availability."
  type        = string
  default     = "us-east-1"
}

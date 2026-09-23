provider "aws" {
  region = var.aws_region
}

# The bucket that will hold every environment's terraform.tfstate file.
# prevent_destroy guards against an accidental `terraform destroy` wiping out
# the state for every environment at once - to actually remove this bucket,
# you must deliberately delete this lifecycle block first.
# AWS-0089 (access logging): would need a second bucket to receive logs -
# real observability value, but deferred as a future enhancement.
#tfsec:ignore:AWS-0089
resource "aws_s3_bucket" "terraform_state" {
  bucket = var.bucket_name

  lifecycle {
    prevent_destroy = true
  }
}

# Versioning lets us recover a previous state file (e.g. after a bad apply
# or accidental manual edit) instead of losing history permanently.
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# State files can contain sensitive values (DB passwords, ARNs, etc.), so
# encrypt at rest. AES256 (SSE-S3) is free, unlike SSE-KMS which bills per
# request - fine for a learning project with no compliance requirement for
# customer-managed keys.
# AWS-0132 (customer-managed KMS key): SSE-S3 already encrypts at rest;
# CMK adds ~$1/mo + key rotation management not justified here.
#tfsec:ignore:AWS-0132
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# State must never be publicly reachable - block every public-access avenue
# S3 supports, even if a future bucket policy or ACL tries to allow it.
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Provides distributed locking so two `terraform apply` runs (e.g. from two
# people, or a laptop + CI) can't corrupt state by writing at the same time.
# LockID is the exact attribute name Terraform's S3 backend requires.
# AWS-0025 (customer-managed KMS key): AWS-managed encryption is already on
# by default; CMK adds cost/complexity not justified here (same tradeoff
# as the state bucket's encryption above).
#tfsec:ignore:AWS-0025
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-locks"
  billing_mode = "PAY_PER_REQUEST" # no capacity planning; you pay per request, ~free at this scale
  hash_key     = "LockID"

  # Free to enable, cheap insurance against this table (the only thing
  # guarding concurrent applies across every environment) being corrupted.
  point_in_time_recovery {
    enabled = true
  }

  attribute {
    name = "LockID"
    type = "S"
  }
}

# global/backend

One-time bootstrap Terraform config for remote state.

Provisions the S3 bucket (state storage) and DynamoDB table (state locking)
used by every environment. Applied once, before any environment exists.

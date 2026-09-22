# This config now uses S3 remote state for itself, pointing at the bucket
# and DynamoDB table it created in step 1. NOTE: this is a self-referential
# backend - if the bucket/table is ever lost or needs to be rebuilt, there is
# no local state fallback to recover from. Deliberate tradeoff, chosen over
# keeping this config on local state permanently.
#
# The block is left empty (partial config) because backend blocks cannot
# reference variables or resource attributes - values are supplied at
# `terraform init` time via -backend-config flags (see migration command).

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # pinned so provider updates can't silently change behavior
    }
  }

  backend "s3" {}
}

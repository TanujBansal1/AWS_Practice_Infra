# Same pin as global/backend, so all configs in this project resolve the
# same provider version.
terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # Partial config, same pattern as global/backend - filled via
  # -backend-config flags at `terraform init` time.
  backend "s3" {}
}

provider "aws" {
  region = var.aws_region
}

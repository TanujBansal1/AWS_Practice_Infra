bucket         = "tanay-tf-state-phase-one"
key            = "global/ci-user/terraform.tfstate"
region         = "us-east-1"
dynamodb_table = "terraform-locks"
encrypt        = true
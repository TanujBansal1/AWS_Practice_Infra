variable "aws_region" {
  description = "AWS region for the GitHub OIDC bootstrap resources."
  type        = string
  default     = "us-east-1"
}

variable "github_repository" {
  description = "Exact GitHub repository slug in owner/repo form that is allowed to assume the role."
  type        = string
}

variable "role_name" {
  description = "Name of the IAM role assumed by GitHub Actions."
  type        = string
  default     = "github-oidc-deploy-role"
}

variable "tags" {
  description = "Optional tags applied to IAM resources."
  type        = map(string)
  default     = {}
}
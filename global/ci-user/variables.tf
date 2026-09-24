variable "aws_region" {
  description = "AWS region used for region-scoped IAM ARNs and Terraform operations."
  type        = string
  default     = "us-east-1"
}

variable "tags" {
  description = "Optional tags applied to the IAM user."
  type        = map(string)
  default     = {}
}
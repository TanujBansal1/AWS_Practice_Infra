variable "name_prefix" {
  description = "Prefix used to tag/name all resources created by this module (e.g. \"todo-dev\")."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid CIDR block (e.g. 10.0.0.0/16)."
  }
}

variable "enable_nat_gateway" {
  description = "Whether to create a NAT Gateway for private subnet egress. NAT Gateway is NOT free-tier (hourly + per-GB cost) - set to false to save money when private subnets don't need outbound internet (e.g. no ECR/RDS access needed yet)."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags merged onto every resource in this module (e.g. Project, Environment, ManagedBy)."
  type        = map(string)
  default     = {}
}

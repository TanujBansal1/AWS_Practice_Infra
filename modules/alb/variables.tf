variable "name_prefix" {
  description = "Prefix used to tag/name all resources created by this module."
  type        = string
}

variable "vpc_id" {
  description = "VPC to create the ALB and its security group in."
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs the ALB will be placed in (needs 2+ AZs)."
  type        = list(string)
}

variable "container_port" {
  description = "Port the application container listens on (target group forwards here)."
  type        = number
  default     = 8000

  validation {
    condition     = var.container_port > 0 && var.container_port <= 65535
    error_message = "container_port must be between 1 and 65535."
  }
}

variable "tags" {
  description = "Common tags merged onto every resource in this module (e.g. Project, Environment, ManagedBy)."
  type        = map(string)
  default     = {}
}

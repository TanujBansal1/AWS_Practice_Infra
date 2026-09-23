variable "repository_name" {
  description = "Name of the ECR repository (e.g. \"todo-api\")."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]+(?:[._-][a-z0-9]+)*$", var.repository_name))
    error_message = "repository_name must match AWS ECR naming rules: lowercase letters, numbers, and single '.', '_', or '-' separators."
  }
}

variable "tags" {
  description = "Common tags merged onto every resource in this module (e.g. Project, Environment, ManagedBy)."
  type        = map(string)
  default     = {}
}

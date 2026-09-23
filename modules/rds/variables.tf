variable "name_prefix" {
  description = "Prefix used to tag/name all resources created by this module."
  type        = string
}

variable "vpc_id" {
  description = "VPC the RDS instance and its security group live in."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for the DB subnet group (needs at least 2 AZs)."
  type        = list(string)
}

variable "ecs_sg_id" {
  description = "ECS tasks security group ID - the RDS security group only allows ingress from this SG (SG-to-SG chaining, no CIDR)."
  type        = string
}

variable "instance_class" {
  description = "RDS instance class. db.t3.micro is free-tier eligible (750 hrs/month for 12 months)."
  type        = string
  default     = "db.t3.micro"

  validation {
    condition     = can(regex("^db\\.", var.instance_class))
    error_message = "instance_class must be a valid RDS instance class starting with 'db.' (e.g. db.t3.micro)."
  }
}

variable "allocated_storage" {
  description = "Allocated storage in GB. 20GB is within the RDS free tier."
  type        = number
  default     = 20

  validation {
    condition     = var.allocated_storage >= 20
    error_message = "allocated_storage must be at least 20GB (RDS Postgres minimum for gp2/gp3 storage)."
  }
}

variable "engine_version" {
  description = "PostgreSQL engine version."
  type        = string
  default     = "16"
}

variable "multi_az" {
  description = "Whether to run Multi-AZ for automatic failover. Roughly doubles RDS cost (a full standby replica) - default false to stay cheap for dev."
  type        = bool
  default     = false
}

variable "db_name" {
  description = "Name of the initial database created on the instance."
  type        = string
  default     = "todos"
}

variable "master_username" {
  description = "Master username for the RDS instance."
  type        = string
  default     = "todo_app"
}

variable "skip_final_snapshot" {
  description = "If true, terraform destroy deletes the instance without taking a final snapshot - data is lost permanently. Fine for dev/learning; should be false for anything with real data."
  type        = bool
  default     = true
}

variable "backup_retention_period" {
  description = "Automated backup retention in days. Kept short to limit storage cost for a dev environment."
  type        = number
  default     = 1
}

variable "tags" {
  description = "Common tags merged onto every resource in this module (e.g. Project, Environment, ManagedBy)."
  type        = map(string)
  default     = {}
}

variable "deletion_protection" {
  description = "Whether to enable RDS deletion protection (a Terraform destroy or console delete is rejected until this is turned off first). Default false for dev convenience; should be true for staging/prod."
  type        = bool
  default     = false
}

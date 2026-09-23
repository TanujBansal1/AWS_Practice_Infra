variable "name_prefix" {
  description = "Prefix used to tag/name all resources created by this module."
  type        = string
}

variable "vpc_id" {
  description = "VPC the ECS tasks run in (needed for the tasks' security group)."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs the ECS tasks are placed in."
  type        = list(string)
}

variable "alb_sg_id" {
  description = "ALB security group ID - the ECS tasks security group only allows ingress from this SG (SG-to-SG chaining, no CIDR)."
  type        = string
}

variable "target_group_arn" {
  description = "ALB target group ARN the ECS service registers its tasks with."
  type        = string
}

variable "container_port" {
  description = "Port the application container listens on."
  type        = number
  default     = 8000

  validation {
    condition     = var.container_port > 0 && var.container_port <= 65535
    error_message = "container_port must be between 1 and 65535."
  }
}

variable "image_url" {
  description = "Full ECR image URI (including tag) to run, e.g. <account>.dkr.ecr.<region>.amazonaws.com/todo-api:latest."
  type        = string
}

variable "desired_count" {
  description = "Number of Fargate tasks to run. Ignored after creation if enable_autoscaling is true (autoscaling then owns this value)."
  type        = number
  default     = 2

  validation {
    condition     = var.desired_count >= 1
    error_message = "desired_count must be at least 1."
  }
}

variable "cpu" {
  description = "Fargate task CPU units (256 = .25 vCPU, cheapest Fargate size)."
  type        = string
  default     = "256"

  validation {
    condition     = contains(["256", "512", "1024", "2048", "4096"], var.cpu)
    error_message = "cpu must be one of the valid Fargate CPU values: 256, 512, 1024, 2048, 4096."
  }
}

variable "memory" {
  description = "Fargate task memory in MB (512 pairs with 256 CPU, cheapest valid combination)."
  type        = string
  default     = "512"
}

variable "environment_variables" {
  description = "Map of plain (non-secret) environment variables to inject into the container. Use db_secret_arn / Secrets Manager for credentials."
  type        = map(string)
  default     = {}
}

variable "db_secret_arn" {
  description = "ARN of the Secrets Manager secret holding DB credentials (host, port, dbname, username, password keys). Injected into the container via the task definition's \"secrets\" block, resolved by the execution role."
  type        = string
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days - kept short to limit log storage cost."
  type        = number
  default     = 7
}

variable "tags" {
  description = "Common tags merged onto every resource in this module (e.g. Project, Environment, ManagedBy)."
  type        = map(string)
  default     = {}
}

variable "enable_autoscaling" {
  description = "Whether to attach Application Auto Scaling (target tracking on CPU) to the ECS service. When true, desired_count becomes the initial value only - the autoscaler owns it afterward."
  type        = bool
  default     = false
}

variable "min_capacity" {
  description = "Minimum number of tasks when autoscaling is enabled."
  type        = number
  default     = 2
}

variable "max_capacity" {
  description = "Maximum number of tasks when autoscaling is enabled."
  type        = number
  default     = 6
}

check "autoscaling_capacity_range" {
  assert {
    condition     = var.min_capacity <= var.max_capacity
    error_message = "min_capacity must be less than or equal to max_capacity."
  }
}

variable "name_prefix" {
  description = "Prefix used to tag/name all resources created by this module."
  type        = string
}

variable "price_class" {
  description = "CloudFront price class. PriceClass_100 (US/Canada/Europe edge locations only) is the cheapest option and plenty for a demo/learning project."
  type        = string
  default     = "PriceClass_100"
}

variable "tags" {
  description = "Common tags merged onto every resource in this module (e.g. Project, Environment, ManagedBy)."
  type        = map(string)
  default     = {}
}

variable "alb_dns_name" {
  description = "ALB DNS name, proxied through this CloudFront distribution so the browser (loaded over HTTPS) never has to make a mixed-content HTTP request straight to the ALB."
  type        = string
}

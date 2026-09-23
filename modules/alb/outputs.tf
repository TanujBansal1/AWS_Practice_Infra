output "alb_sg_id" {
  description = "ALB security group ID - referenced by the ECS module to allow only ALB->ECS traffic."
  value       = aws_security_group.alb.id
}

output "alb_dns_name" {
  description = "Public DNS name of the ALB - use this to curl the app."
  value       = aws_lb.app.dns_name
}

output "target_group_arn" {
  description = "Target group ARN - ECS service registers its tasks here."
  value       = aws_lb_target_group.app.arn
}

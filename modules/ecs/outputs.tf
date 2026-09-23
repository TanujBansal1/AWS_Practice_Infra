output "cluster_name" {
  description = "ECS cluster name."
  value       = aws_ecs_cluster.main.name
}

output "service_name" {
  description = "ECS service name."
  value       = local.ecs_service_name
}

output "ecs_tasks_sg_id" {
  description = "ECS tasks security group ID - referenced by modules/rds so the database only accepts ingress from ECS."
  value       = aws_security_group.ecs_tasks.id
}

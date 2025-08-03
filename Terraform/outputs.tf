# DB
output "database_endpoint" {
  description = "Database endpoint"
  value       = aws_db_instance.main.endpoint
  sensitive   = true
}

output "database_port" {
  description = "Database port"
  value       = aws_db_instance.main.port
}

# -------------------

#ECS Cluster Info
output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.app.name
}
output "load_balancer_dns" {
  description = "DNS name of the load balancer"
  value       = aws_lb.main.dns_name
}

output "load_balancer_url" {
  description = "URL of the load balancer"
  value       = "http://${aws_lb.main.dns_name}"
}

# -------------------

# VPC
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "log_group_name" {
  description = "CloudWatch log group name"
  value       = aws_cloudwatch_log_group.app.name
}
# -------------------

# Bastion
output "bastion_public_ip" {
  description = "Public IP of bastion host"
  value       = var.enable_bastion ? aws_instance.bastion[0].public_ip : null
}

output "bastion_connection_command" {
  description = "SSH command to connect to bastion host"
  value       = var.enable_bastion ? "ssh -i ~/.ssh/${var.bastion_key_name}.pem ec2-user@${aws_instance.bastion[0].public_ip}" : null
}
# -------------------

# ECS AutoScaling

output "ecs_autoscaling_target_arn" {
  description = "ECS Auto Scaling Target ARN"
  value       = aws_appautoscaling_target.ecs_target.arn
}

output "ecs_cpu_scaling_policy_arn" {
  description = "ECS CPU Scaling Policy ARN"
  value       = aws_appautoscaling_policy.ecs_cpu_policy.arn
}

output "ecs_memory_scaling_policy_arn" {
  description = "ECS Memory Scaling Policy ARN"
  value       = aws_appautoscaling_policy.ecs_memory_policy.arn
}
# -------------------

# RDS Replica
output "rds_master_endpoint" {
  description = "RDS Master endpoint"
  value       = aws_db_instance.main.endpoint
}

output "rds_replica_endpoint" {
  description = "RDS Read Replica endpoint"
  value       = aws_db_instance.read_replica.endpoint
}

output "rds_master_arn" {
  description = "RDS Master ARN"
  value       = aws_db_instance.main.arn
}

output "rds_replica_arn" {
  description = "RDS Read Replica ARN"
  value       = aws_db_instance.read_replica.arn
}

output "rds_read_replica_connection_parameter" {
  description = "SSM Parameter for read replica connection string"
  value       = aws_ssm_parameter.db_read_replica_connection_string.name
  sensitive   = true
}
output "rds_replica_lag_alarm_arn" {
  description = "RDS Replica Lag Alarm ARN"
  value       = aws_cloudwatch_metric_alarm.rds_replica_lag.arn
}
# ----------

# AutoScaling CPU alerts
output "ecs_cpu_alarm_arn" {
  description = "ECS CPU High Alarm ARN"
  value       = aws_cloudwatch_metric_alarm.ecs_service_cpu_high.arn
}

output "rds_master_cpu_alarm_arn" {
  description = "RDS Master CPU High Alarm ARN"
  value       = aws_cloudwatch_metric_alarm.rds_master_cpu_high.arn
}


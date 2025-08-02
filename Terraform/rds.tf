# RDS Security Group
resource "aws_security_group" "rds" {
  name_prefix = "${var.app_name}-${var.environment}-rds-"
  vpc_id      = aws_vpc.main.id
  description = "Security group for RDS"

  ingress {
    description     = "PostgreSQL from ECS"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  # Allow access from bastion if enabled
  dynamic "ingress" {
    for_each = var.enable_bastion ? [1] : []
    content {
      description     = "PostgreSQL from Bastion"
      from_port       = 5432
      to_port         = 5432
      protocol        = "tcp"
      security_groups = [aws_security_group.bastion[0].id]
    }
  }

  tags = {
    Name = "${var.app_name}-${var.environment}-rds-sg"
  }
}

# RDS Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.app_name}-${var.environment}-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "${var.app_name}-${var.environment}-db-subnet-group"
  }
}

# Enhanced Monitoring IAM Role for RDS
resource "aws_iam_role" "rds_enhanced_monitoring" {
  name = "${var.app_name}-${var.environment}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.app_name}-${var.environment}-rds-monitoring-role"
  }
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  role       = aws_iam_role.rds_enhanced_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# RDS PostgreSQL Master Instance
resource "aws_db_instance" "main" {
  identifier     = "${var.app_name}-${var.environment}-db"
  engine         = "postgres"
  engine_version = "16.3"
  instance_class = var.db_instance_class

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp2"
  storage_encrypted     = true

  db_name  = "helloworld"
  username = var.db_username
  password = random_password.db_password.result

  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  # DR-focused backup configuration
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"

  # Essential for read replica creation
  skip_final_snapshot = false
  final_snapshot_identifier = "${var.app_name}-${var.environment}-db-final-snapshot"
  deletion_protection = var.environment == "prod" ? true : false

  # Enhanced monitoring for better DR insights
  performance_insights_enabled = true
  performance_insights_retention_period = 7
  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_enhanced_monitoring.arn

  # Allow minor version upgrades for security
  auto_minor_version_upgrade = true

  # Multi-AZ deployment for high availability (optional but recommended for prod)
  multi_az = var.environment == "prod" ? true : false

  tags = {
    Name = "${var.app_name}-${var.environment}-db"
    Role = "Master"
    DR   = "true"
  }
}

# ==========================================
# RDS DISASTER RECOVERY - READ REPLICA
# ==========================================

# Read Replica in different AZ for DR
resource "aws_db_instance" "read_replica" {
  identifier                = "${var.app_name}-${var.environment}-db-replica"
  replicate_source_db       = aws_db_instance.main.identifier
  instance_class            = var.db_replica_instance_class
  publicly_accessible       = false
  auto_minor_version_upgrade = true

  # Place in different AZ for DR
  availability_zone = var.replica_availability_zone

  vpc_security_group_ids = [aws_security_group.rds.id]

  # Enhanced monitoring for replica
  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_enhanced_monitoring.arn

  # Performance Insights
  performance_insights_enabled = true
  performance_insights_retention_period = 7

  # Backup settings for replica
  backup_retention_period = 7
  backup_window          = "03:30-04:30"  # Different from master

  skip_final_snapshot = false
  final_snapshot_identifier = "${var.app_name}-${var.environment}-db-replica-final-snapshot"

  tags = {
    Name = "${var.app_name}-${var.environment}-db-replica"
    Role = "ReadReplica"
    DR   = "true"
  }
}

# Create a parameter to store read replica endpoint for application use
resource "aws_ssm_parameter" "db_read_replica_connection_string" {
  name  = "/${var.app_name}/${var.environment}/db_read_replica_url"
  type  = "SecureString"
  value = "postgresql://${var.db_username}:${random_password.db_password.result}@${aws_db_instance.read_replica.endpoint}:5432/helloworld"

  tags = {
    Name = "${var.app_name}-${var.environment}-db-read-replica-connection"
  }
}

# ==========================================
# CLOUDWATCH ALARMS FOR RDS MONITORING
# ==========================================

# RDS Master Health Alarm
resource "aws_cloudwatch_metric_alarm" "rds_master_cpu_high" {
  alarm_name          = "${var.app_name}-${var.environment}-rds-master-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "85"
  alarm_description   = "RDS Master CPU utilization is too high"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }

  tags = {
    Name = "${var.app_name}-${var.environment}-rds-master-cpu-alarm"
  }
}

# RDS Read Replica Health Alarm
resource "aws_cloudwatch_metric_alarm" "rds_replica_lag" {
  alarm_name          = "${var.app_name}-${var.environment}-rds-replica-lag"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ReplicaLag"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "300"  # 5 minutes lag
  alarm_description   = "RDS Read Replica lag is too high"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.read_replica.id
  }

  tags = {
    Name = "${var.app_name}-${var.environment}-rds-replica-lag-alarm"
  }
}

# ==========================================
# CROSS-REGION RDS REPLICA CONFIGURATION
# ==========================================

# Add to your existing rds.tf

# Data source to get primary DB ARN for cross-region replica
data "aws_db_instance" "primary_db" {
  count = var.enable_cross_region_replica && !var.is_primary_region ? 1 : 0

  db_instance_identifier = var.primary_db_identifier

  provider = aws.primary_region
}

# Cross-region read replica (only in secondary region)
resource "aws_db_instance" "cross_region_replica" {
  count = var.enable_cross_region_replica && !var.is_primary_region ? 1 : 0

  identifier                = "${var.app_name}-${var.environment}-db-cross-region-replica"
  replicate_source_db       = data.aws_db_instance.primary_db[0].arn
  instance_class            = var.db_cross_region_replica_instance_class
  publicly_accessible       = false
  auto_minor_version_upgrade = true

  vpc_security_group_ids = [aws_security_group.rds.id]

  # Enhanced monitoring
  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_enhanced_monitoring.arn

  # Performance Insights
  performance_insights_enabled = true
  performance_insights_retention_period = 7

  # Different backup window for DR
  backup_retention_period = 7
  backup_window          = "04:00-05:00"

  skip_final_snapshot = false
  final_snapshot_identifier = "${var.app_name}-${var.environment}-db-cross-region-replica-final"

  tags = {
    Name = "${var.app_name}-${var.environment}-db-cross-region-replica"
    Role = "CrossRegionReplica"
    DR   = "true"
    PrimaryRegion = var.primary_region
  }
}

# SSM Parameter for cross-region replica connection (in secondary region only)
resource "aws_ssm_parameter" "db_cross_region_replica_connection_string" {
  count = var.enable_cross_region_replica && !var.is_primary_region ? 1 : 0

  name  = "/${var.app_name}/${var.environment}/db_cross_region_replica_url"
  type  = "SecureString"
  value = "postgresql://${var.db_username}:${data.aws_db_instance.primary_db[0].password}@${aws_db_instance.cross_region_replica[0].endpoint}:5432/helloworld"

  tags = {
    Name = "${var.app_name}-${var.environment}-db-cross-region-replica-connection"
  }
}

# ==========================================
# ROUTE53 HEALTH CHECKS & DNS FAILOVER
# ==========================================

# Route53 Hosted Zone (create in primary region only)
resource "aws_route53_zone" "main" {
  count = var.enable_route53_failover && var.is_primary_region ? 1 : 0

  name = var.domain_name

  tags = {
    Name = "${var.app_name}-${var.environment}-zone"
  }
}

# Health Check for Primary Region ALB (create in primary region only)
resource "aws_route53_health_check" "primary" {
  count = var.enable_route53_failover && var.is_primary_region ? 1 : 0

  fqdn                            = aws_lb.app.dns_name
  port                            = 443
  type                            = "HTTPS"
  resource_path                   = "/health"
  failure_threshold               = "3"
  request_interval                = "30"
  cloudwatch_logs_region          = var.aws_region
  cloudwatch_alarm_region         = var.aws_region
  insufficient_data_health_status = "Failure"

  tags = {
    Name = "${var.app_name}-${var.environment}-primary-health-check"
  }
}

# Primary Region DNS Record (Weighted)
resource "aws_route53_record" "primary" {
  count = var.enable_route53_failover && var.is_primary_region ? 1 : 0

  zone_id = aws_route53_zone.main[0].zone_id
  name    = "api.${var.domain_name}"
  type    = "A"

  set_identifier = "primary-${var.aws_region}"

  weighted_routing_policy {
    weight = 100
  }

  health_check_id = aws_route53_health_check.primary[0].id

  alias {
    name                   = aws_lb.app.dns_name
    zone_id               = aws_lb.app.zone_id
    evaluate_target_health = true
  }
}

# Data source to get primary region hosted zone (for secondary region)
data "aws_route53_zone" "main" {
  count = var.enable_route53_failover && !var.is_primary_region ? 1 : 0

  name = var.domain_name

  provider = aws.primary_region
}

# Secondary Region DNS Record (Failover)
resource "aws_route53_record" "secondary" {
  count = var.enable_route53_failover && !var.is_primary_region ? 1 : 0

  zone_id = data.aws_route53_zone.main[0].zone_id
  name    = "api.${var.domain_name}"
  type    = "A"

  set_identifier = "secondary-${var.aws_region}"

  failover_routing_policy {
    type = "SECONDARY"
  }

  alias {
    name                   = aws_lb.app.dns_name
    zone_id               = aws_lb.app.zone_id
    evaluate_target_health = true
  }

  provider = aws.primary_region
}

# ==========================================
# ECS STANDBY CONFIGURATION
# ==========================================

# Override ECS service for DR region
resource "aws_ecs_service" "app_dr" {
  count = !var.is_primary_region ? 1 : 0

  name            = "${var.app_name}-${var.environment}"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.is_primary_region ? var.desired_count : 0  # Start at 0 for DR
  launch_type     = "FARGATE"

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  enable_execute_command = false

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = aws_subnet.private[*].id
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = var.app_name
    container_port   = var.container_port
  }

  depends_on = [aws_lb_listener.app]

  tags = {
    Name = "${var.app_name}-${var.environment}"
    Role = "DR"
  }
}


resource "aws_cloudwatch_metric_alarm" "cross_region_replica_lag" {
  count = var.enable_cross_region_replica && !var.is_primary_region ? 1 : 0

  alarm_name          = "${var.app_name}-${var.environment}-cross-region-replica-lag"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "ReplicaLag"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "600"  # 10 minutes lag
  alarm_description   = "Cross-region RDS replica lag is too high"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.cross_region_replica[0].id
  }

  tags = {
    Name = "${var.app_name}-${var.environment}-cross-region-replica-lag-alarm"
  }
}


resource "aws_cloudwatch_metric_alarm" "route53_health_check" {
  count = var.enable_route53_failover && var.is_primary_region ? 1 : 0

  alarm_name          = "${var.app_name}-${var.environment}-route53-health-check-failed"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  period              = "60"
  statistic           = "Minimum"
  threshold           = "1"
  alarm_description   = "Route53 health check is failing"

  dimensions = {
    HealthCheckId = aws_route53_health_check.primary[0].id
  }

  tags = {
    Name = "${var.app_name}-${var.environment}-route53-health-check-alarm"
  }
}
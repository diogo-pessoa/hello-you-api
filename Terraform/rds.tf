# Network rules
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

# Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.app_name}-${var.environment}-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "${var.app_name}-${var.environment}-db-subnet-group"
  }
}
# -------------------

# IAM
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
# -------------------

# PostgreSQL Master Instance
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

  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"

  skip_final_snapshot = true
  final_snapshot_identifier = "${var.app_name}-${var.environment}-db-final-snapshot"
  deletion_protection = var.environment == "prod" ? true : false

  performance_insights_enabled = true
  performance_insights_retention_period = 7
  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_enhanced_monitoring.arn

  auto_minor_version_upgrade = true

  multi_az = var.environment == "prod" ? true : false

  tags = {
    Name = "${var.app_name}-${var.environment}-db"
    Role = "Master"
    DR   = "true"
  }
}

# -------------------

# READ REPLICA

resource "aws_db_instance" "read_replica" {
  identifier                = "${var.app_name}-${var.environment}-db-replica"
  replicate_source_db       = aws_db_instance.main.identifier
  instance_class            = var.db_replica_instance_class
  publicly_accessible       = false
  auto_minor_version_upgrade = true
  skip_final_snapshot        = true
  # Place in different AZ for DR
  availability_zone = var.replica_availability_zone
  storage_encrypted = true
  vpc_security_group_ids = [aws_security_group.rds.id]

  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_enhanced_monitoring.arn

  performance_insights_enabled = true
  performance_insights_retention_period = 7

  backup_retention_period = 7
  backup_window          = "08:30-12:30"  # Different from master

  final_snapshot_identifier = "${var.app_name}-${var.environment}-db-replica-final-snapshot"

  tags = {
    Name = "${var.app_name}-${var.environment}-db-replica"
    Role = "ReadReplica"
    DR   = "true"
  }
}

resource "aws_ssm_parameter" "db_read_replica_connection_string" {
  name  = "/${var.app_name}/${var.environment}/db_read_replica_url"
  type  = "SecureString"
  value = "postgresql://${var.db_username}:${random_password.db_password.result}@${aws_db_instance.read_replica.endpoint}:5432/helloworld"

  tags = {
    Name = "${var.app_name}-${var.environment}-db-read-replica-connection"
  }
}


# -------------------

# CLOUDWATCH ALARMS
# Master Health Alarm
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

# Read Replica Health Alarm
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

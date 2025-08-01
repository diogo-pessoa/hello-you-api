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

# RDS PostgreSQL Instance
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
  deletion_protection = false

  tags = {
    Name = "${var.app_name}-${var.environment}-db"
  }
}
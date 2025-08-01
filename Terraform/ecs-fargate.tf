# ECS Tasks Security Group
resource "aws_security_group" "ecs_tasks" {
  name_prefix = "${var.app_name}-${var.environment}-ecs-"
  vpc_id      = aws_vpc.main.id
  description = "Security group for ECS tasks"

  ingress {
    description     = "From ALB"
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.app_name}-${var.environment}-ecs-sg"
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = local.cluster_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = local.cluster_name
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "app" {
  name              = "/aws/ecs/${local.cluster_name}"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "${var.app_name}-${var.environment}-logs"
  }
}

# ECS Task Definition
resource "aws_ecs_task_definition" "app" {
  family                   = "${var.app_name}-${var.environment}"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn           = aws_iam_role.ecs_task_role.arn
  network_mode            = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                     = var.task_cpu
  memory                  = var.task_memory

  container_definitions = jsonencode([{
    name  = var.app_name
    image = var.container_image

    portMappings = [{
      containerPort = var.container_port
      protocol      = "tcp"
    }]

    environment = [
      {
        name  = "FLASK_ENV"
        value = "production"
      },
      {
        name  = "PORT"
        value = tostring(var.container_port)
      },
      {
        name  = "LOG_LEVEL"
        value = "INFO"
      }
    ]

    secrets = [
      {
        name      = "SECRET_KEY"
        valueFrom = aws_ssm_parameter.flask_secret_key.arn
      },
      {
        name      = "DATABASE_URL"
        valueFrom = aws_ssm_parameter.db_connection_string.arn
      }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.app.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }

    essential = true
  }])

  tags = {
    Name = "${var.app_name}-${var.environment}"
  }
}

# ECS Service
resource "aws_ecs_service" "app" {
  name            = "${var.app_name}-${var.environment}"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.desired_count
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
  }
}
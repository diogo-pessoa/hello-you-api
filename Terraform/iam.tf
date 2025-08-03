resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.app_name}-${var.environment}-ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.app_name}-${var.environment}-execution-role"
  }
}


resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_attach" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task_role" {
  name = "${var.app_name}-${var.environment}-ecsTaskRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.app_name}-${var.environment}-task-role"
  }
}

resource "aws_iam_policy" "ecs_task_policy" {
  name        = "${var.app_name}-${var.environment}-ecs-task-policy"
  description = "Least-privilege policy for ECS tasks"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "SSMReadAccess",
        Effect = "Allow",
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ],
        Resource = [
          aws_ssm_parameter.flask_secret_key.arn,
          aws_ssm_parameter.db_connection_string.arn
        ]
      },
      {
        Sid    = "SecretsManagerReadAccess",
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue"
        ],
        Resource = aws_secretsmanager_secret.github_registry_credentials.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_attach_policy" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_task_policy.arn
}

resource "aws_iam_policy" "ecs_execution_ssm_policy" {
  name        = "${var.app_name}-${var.environment}-ecs-execution-ssm-policy"
  description = "Allow ECS execution role to read secrets from SSM and Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "SSMReadAccess",
        Effect = "Allow",
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ],
        Resource = [
          aws_ssm_parameter.flask_secret_key.arn,
          aws_ssm_parameter.db_connection_string.arn
        ]
      },
      {
        Sid    = "SecretsManagerReadAccess",
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue"
        ],
        Resource = aws_secretsmanager_secret.github_registry_credentials.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_ssm_attach" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_execution_ssm_policy.arn
}

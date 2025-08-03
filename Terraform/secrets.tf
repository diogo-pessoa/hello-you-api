
resource "random_password" "db_password" {
  length           = 32
  special          = true
  override_special = "_%#=+,.^~-" # Allowed RDS special characters
}

resource "random_password" "flask_secret_key" {
  length  = 64
  special = true
}

resource "aws_ssm_parameter" "db_password" {
  name  = "/${var.app_name}/${var.environment}/db-password"
  type  = "SecureString"
  value = random_password.db_password.result

  tags = {
    Name = "${var.app_name}-${var.environment}-db-password"
  }
}

resource "aws_ssm_parameter" "flask_secret_key" {
  name  = "/${var.app_name}/${var.environment}/flask-secret-key"
  type  = "SecureString"
  value = random_password.flask_secret_key.result

  tags = {
    Name = "${var.app_name}-${var.environment}-flask-secret"
  }
}

resource "aws_ssm_parameter" "db_connection_string" {
  name  = "/${var.app_name}/${var.environment}/database-url"
  type  = "SecureString"
  value = "postgresql://${var.db_username}:${urlencode(random_password.db_password.result)}@${aws_db_instance.main.endpoint}/helloworld"
  tags = {
    Name = "${var.app_name}-${var.environment}-database-url"
  }
}

#### GitHub Credentials setup

resource "aws_secretsmanager_secret" "github_registry_credentials" {
  name                    = "${var.app_name}-${var.environment}-github-registry-creds"
  description             = "GitHub Container Registry credentials"
  recovery_window_in_days = 7

  tags = {
    Name = "${var.app_name}-${var.environment}-github-registry-creds"
  }
}

# TODO -  disabling for now. I've restored the secret and re-imported. TF still tries to re-created will Review in a separate PR
# resource "aws_secretsmanager_secret_version" "github_registry_credentials" {
#   secret_id = aws_secretsmanager_secret.github_registry_credentials.id
#   secret_string = jsonencode({
#     username = var.github_username
#     password = var.github_pat_token
#   })
# }

# 2. Update IAM role to access the secret
resource "aws_iam_policy" "ecs_secrets_policy" {
  name        = "${var.app_name}-${var.environment}-ecs-secrets-policy"
  description = "Policy for ECS to access GitHub registry secrets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          aws_secretsmanager_secret.github_registry_credentials.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_secrets" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_secrets_policy.arn
}
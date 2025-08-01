# Generate random password for RDS
resource "random_password" "db_password" {
  length  = 32
  special = true
}

# Generate random secret key for Flask
resource "random_password" "flask_secret_key" {
  length  = 64
  special = true
}

# Store DB password in SSM Parameter Store
resource "aws_ssm_parameter" "db_password" {
  name  = "/${var.app_name}/${var.environment}/db-password"
  type  = "SecureString"
  value = random_password.db_password.result

  tags = {
    Name = "${var.app_name}-${var.environment}-db-password"
  }
}

# Store Flask secret key in SSM Parameter Store
resource "aws_ssm_parameter" "flask_secret_key" {
  name  = "/${var.app_name}/${var.environment}/flask-secret-key"
  type  = "SecureString"
  value = random_password.flask_secret_key.result

  tags = {
    Name = "${var.app_name}-${var.environment}-flask-secret"
  }
}

# Store complete database connection string
resource "aws_ssm_parameter" "db_connection_string" {
  name  = "/${var.app_name}/${var.environment}/database-url"
  type  = "SecureString"
  value = "postgresql://${var.db_username}:${random_password.db_password.result}@${aws_db_instance.main.endpoint}:5432/helloworld"

  tags = {
    Name = "${var.app_name}-${var.environment}-database-url"
  }
}
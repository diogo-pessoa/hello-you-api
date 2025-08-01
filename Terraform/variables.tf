variable "app_name" {
  description = "Application name"
  type        = string
  default     = "hello-you-api"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-north-1"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = []
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "hello_user"
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "flask_secret_key" {
  description = "Flask secret key"
  type        = string
  sensitive   = true
}

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
  default     = null
}

variable "container_image" {
  description = "Docker image for the application"
  type        = string
  default     = "ghcr.io/diogo-pessoa/hello-you-api:latest"
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 5000
}

variable "health_check_path" {
  description = "uri to check for app health"
  type        = string
  default     = "/health"
}


variable "desired_count" {
  description = "Desired number of tasks"
  type        = number
  default     = 2
}

variable "task_cpu" {
  description = "CPU units for the task"
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "Memory for the task"
  type        = number
  default     = 512
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

variable "enable_bastion" {
  description = "Enable bastion host for debugging"
  type        = bool
  default     = false
}

variable "bastion_key_name" {
  description = "EC2 Key Pair name for bastion host"
  type        = string
  default     = "hello-you-bastion"
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access bastion host"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Restrict this to your IP for security
}
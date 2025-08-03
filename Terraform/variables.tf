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

  validation {
    condition = (
      length(var.db_password) >= 8 &&
      length(var.db_password) <= 41 &&
      can(regex("^[ -~]+$", var.db_password)) && # printable ASCII
      !can(regex("[/@\" ]", var.db_password))    # forbidden characters
    )
    error_message = "Database password must be 8–41 printable ASCII characters and cannot include '/', '@', '\"', or spaces."
  }
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
  default     = ""
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


variable "github_username" {
  description = "GitHub username for container registry access"
  type        = string
  default     = ""
}

variable "github_pat_token" {
  description = "GitHub Personal Access Token for container registry access"
  type        = string
  sensitive   = true
  default     = null
}


variable "min_capacity" {
  description = "Minimum number of ECS tasks"
  type        = number
  default     = 1

  validation {
    condition     = var.min_capacity >= 1
    error_message = "Minimum capacity must be at least 1."
  }
}

locals {
  ecs_capacity_valid = var.max_capacity >= var.min_capacity
}

resource "null_resource" "validate_capacity" {
  count = local.ecs_capacity_valid ? 0 : 1

  provisioner "local-exec" {
    command = "echo 'ERROR: max_capacity must be >= min_capacity' && exit 1"
  }
}


variable "max_capacity" {
  description = "Maximum number of ECS tasks"
  type        = number
  default     = 6

  validation {
    condition     = var.max_capacity >= 1
    error_message = "Maximum capacity must be greater than or equal to 1."
  }
}

variable "db_replica_instance_class" {
  description = "Instance class for RDS read replica"
  type        = string
  default     = "db.t3.micro"

  validation {
    condition = contains([
      "db.t3.micro", "db.t3.small", "db.t3.medium", "db.t3.large",
      "db.t3.xlarge", "db.t3.2xlarge", "db.m5.large", "db.m5.xlarge",
      "db.m5.2xlarge", "db.m5.4xlarge", "db.r5.large", "db.r5.xlarge"
    ], var.db_replica_instance_class)
    error_message = "DB replica instance class must be a valid RDS instance type."
  }
}

variable "replica_availability_zone" {
  description = "Availability zone for read replica (should be different from master)"
  type        = string
  default     = null
}


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

# Github registry credentials:

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

# ==========================================
# ECS AUTO SCALING VARIABLES
# ==========================================

variable "min_capacity" {
  description = "Minimum number of ECS tasks"
  type        = number
  default     = 1

  validation {
    condition     = var.min_capacity >= 1
    error_message = "Minimum capacity must be at least 1."
  }
}

variable "max_capacity" {
  description = "Maximum number of ECS tasks"
  type        = number
  default     = 6

  validation {
    condition     = var.max_capacity >= var.min_capacity
    error_message = "Maximum capacity must be greater than or equal to minimum capacity."
  }
}

# ==========================================
# RDS DISASTER RECOVERY VARIABLES
# ==========================================

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


# ==========================================
# ADDITIONAL VARIABLES FOR CROSS-REGION
# ==========================================

variable "enable_cross_region_replica" {
  description = "Enable cross-region read replica for disaster recovery"
  type        = bool
  default     = false
}

variable "is_primary_region" {
  description = "Whether this is the primary region deployment"
  type        = bool
  default     = true
}

variable "primary_region" {
  description = "Primary AWS region"
  type        = string
  default     = "us-east-1"
}

variable "primary_db_identifier" {
  description = "Primary database identifier for cross-region replica"
  type        = string
  default     = ""
}

variable "db_cross_region_replica_instance_class" {
  description = "Instance class for cross-region RDS read replica"
  type        = string
  default     = "db.t3.small"
}

variable "enable_route53_failover" {
  description = "Enable Route53 DNS failover configuration"
  type        = bool
  default     = false
}

variable "domain_name" {
  description = "Domain name for Route53 hosted zone"
  type        = string
  default     = ""
}

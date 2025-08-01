terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "hello-you-api"
    key    = "ecs/terraform.tfstate"
    region = "eu-north-1"
    encrypt = true
  }
}

provider "aws" {
  region = var.aws_region

  # Optional: Configure default tags for all resources
  default_tags {
    tags = {
      Project     = var.app_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
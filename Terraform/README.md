# ECS Fargate Flask Application Infrastructure

This Terraform project deploys a **production-ready Flask API** on **AWS ECS Fargate** with:

* PostgreSQL (RDS)
* Application Load Balancer
* Secure VPC Networking
* Automated Secrets Management

## Quick Setup

### Prerequisites

* [Terraform](https://developer.hashicorp.com/terraform/downloads) `>= 1.0`
* AWS CLI configured with sufficient permissions
* S3 bucket for remote state (already created)

### Clone and Configure

```bash
git clone <repo-url>
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
```

### Create SSH Key Pair (for optional Bastion)

```bash
aws ec2 create-key-pair \
  --key-name hello-you-bastion \
  --region <region> \
  --query 'KeyMaterial' \
  --output text > ~/.ssh/hello-you-bastion.pem
chmod 400 ~/.ssh/hello-you-bastion.pem
```

### Deploy Infrastructure

```bash
terraform init
terraform plan
terraform apply
```

---

## Features

### ECS Fargate

* Zero-downtime **rolling updates**
* Runs in **private subnets** with NAT Gateway
* Auto scaling with CPU/Memory targets
* Container Insights enabled
* Secure secrets injection from AWS SSM

### RDS PostgreSQL

* Managed PostgreSQL 16.3 with **multi-AZ**
* Encrypted storage, 7-day automated backups
* Automatic scaling to 100GB
* Access restricted to ECS tasks (and optional Bastion)

### Networking

* **VPC** with public and private subnets
* Internet Gateway for public subnets
* NAT Gateway for private subnet internet access
* Strict Security Groups (ECS ↔ RDS only)

### Application Load Balancer

* Public ALB with HTTP(S) listeners
* Health checks for ECS tasks
* Auto-registers/deregisters targets
* Future-ready for SSL and WAF integration

### Secrets and Key Management

* **Randomly generated passwords**
* Stored as SecureString in AWS SSM
* IAM policies restrict access to ECS tasks
* No hardcoded credentials in code or Terraform

### Logging and Monitoring

* ECS logs streamed to **CloudWatch Logs**
* Configurable retention
* Supports JSON/structured logs
* Container Insights for metrics and tracing

### Optional Bastion Host

* SSH access to private resources (RDS)
* Restricted CIDR for SSH
* Pre-installed AWS CLI, Docker, PostgreSQL client

---

## References

* [ecs-terraform](https://github.com/alex/ecs-terraform/blob/master/main.tf)
* [terraform-aws-ecs](https://github.com/anrim/terraform-aws-ecs/blob/master/main.tf)
* [terraform-aws-modules/ecs](https://registry.terraform.io/modules/terraform-aws-modules/ecs/aws/3.1.0/examples/complete-ecs)
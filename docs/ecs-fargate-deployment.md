
# ECS Fargate Flask Application Infrastructure

This Terraform configuration deploys a production-ready Flask application on AWS ECS Fargate with PostgreSQL database, load balancing, and secure networking. The infrastructure follows AWS best practices with automated secret management and comprehensive logging.

## ECS Fargate

The application runs on AWS Fargate, providing serverless container orchestration without managing EC2 instances. Key deployment features include:

- **Rolling Updates**: Configured with 200% maximum deployment percentage and 100% minimum healthy percentage, ensuring zero-downtime deployments
- **Service Discovery**: Tasks are automatically registered with the Application Load Balancer target group
- **Resource Management**: Configurable CPU and memory allocation per task
- **Container Insights**: Enabled for detailed monitoring and performance metrics
- **Network Isolation**: Tasks run in private subnets with no direct internet access
- **Health Checks**: Automatic container health monitoring with configurable thresholds

The ECS service automatically handles task replacement, scaling, and integration with AWS services like CloudWatch and Systems Manager for seamless operations.

## RDS PostgreSQL Instance

A managed PostgreSQL 16.3 database provides persistent storage with enterprise features:

- **Storage**: 20GB initial allocation with auto-scaling up to 100GB using GP2 SSD storage
- **Security**: Database encryption at rest, VPC isolation, and security group restrictions
- **Backup**: 7-day retention period with automated daily backups during low-traffic hours (3-4 AM UTC)
- **Maintenance**: Scheduled maintenance windows on Sundays (4-5 AM UTC) for minimal disruption
- **High Availability**: Deployed across multiple availability zones via subnet groups
- **Connection Security**: Only accessible from ECS tasks and optionally the bastion host

The database password is automatically generated and stored securely in AWS Systems Manager Parameter Store, eliminating the need for hardcoded credentials.

## Bastion Host for Secure Admin Access

An optional Amazon Linux 2 bastion host provides secure administrative access to private resources:

- **Security**: Deployed in public subnet with SSH access restricted to specified CIDR blocks
- **Tools**: Pre-installed with PostgreSQL client, Docker, and AWS CLI v2 for debugging
- **Database Access**: Can connect directly to RDS instance for administrative tasks

## VPC Network Architecture

A comprehensive Virtual Private Cloud provides network isolation and security:

- **Public Subnets**: Host the Application Load Balancer and optional bastion host across multiple AZs
- **Private Subnets**: Contain ECS tasks and RDS instances with no direct internet access
- **Internet Gateway**: Provides internet connectivity for public subnets
- **NAT Gateway**: Enables outbound internet access for private subnet resources (software updates, API calls)
- **Route Tables**: Separate routing for public (via IGW) and private (via NAT) subnets
- **Multi-AZ Design**: Resources distributed across availability zones for high availability
- **DNS Support**: Enabled for service discovery and internal name resolution

The network design follows AWS security best practices with defense-in-depth, ensuring application components can communicate while maintaining isolation from external threats.

## Key and Secrets Management

Automated secret generation eliminates manual credential management:

- **Dynamic Generation**: Database passwords and Flask secret keys are automatically generated using Terraform's `random_password` resource
- **Secure Storage**: All secrets stored in AWS Systems Manager Parameter Store as SecureString type
- **Encryption**: Secrets encrypted using AWS KMS with automatic key rotation capabilities  
- **Access Control**: IAM policies restrict secret access to only the ECS task execution role
- **No Plaintext**: Secrets never stored in Terraform files, version control, or environment variables
- **Container Integration**: ECS tasks retrieve secrets at runtime through AWS Secrets Manager integration

This approach ensures compliance with security best practices and makes credential rotation straightforward without application code changes or redeployment.

## Application Load Balancer

The ALB provides high-availability traffic distribution and SSL termination:

- **Public Access**: Deployed in public subnets with internet-facing configuration
- **Traffic Distribution**: Routes HTTP/HTTPS traffic to healthy ECS tasks across multiple AZs
- **Health Checks**: Configurable health check endpoints with automatic unhealthy target removal
- **Security Groups**: Allows inbound traffic on ports 80/443 from anywhere, restricts backend communication
- **Target Group**: IP-based targeting for Fargate tasks with automatic registration/deregistration
- **Scaling Ready**: Supports future enhancements like SSL certificates, custom domains, and WAF integration

The load balancer automatically handles traffic surge and provides the foundation for implementing advanced features like blue-green deployments and A/B testing.

## CloudWatch Logs

Comprehensive logging provides operational visibility and troubleshooting capabilities:

- **Centralized Logging**: All ECS container logs automatically forwarded to CloudWatch Logs
- **Log Groups**: Organized by ECS cluster with configurable retention periods (default: as per variable)
- **Real-time Monitoring**: Live log streaming for immediate troubleshooting and debugging
- **Log Retention**: Configurable retention periods to balance cost and compliance requirements
- **Integration Ready**: Logs can be easily exported to external systems or analyzed with CloudWatch Insights
- **Structured Logging**: Supports JSON and structured log formats for advanced querying and alerting

The logging configuration enables comprehensive application monitoring, performance analysis, and integration with alerting systems for proactive issue detection and resolution.


### Creating a KeyPair through aws-cli

I created the keyPair manually ahead of running the `bastion.tf`.  

```bash
aws ec2 create-key-pair \
  --key-name pemfile \
  --region eu-north-1 \
  --query 'asdasd' \
  --output text > ~/.ssh/pemfile

chmod 400 ~/.ssh/pemfile
```



#### References:
1. [ecs-terraform](https://github.com/alex/ecs-terraform/blob/master/main.tf)
2. [terraform-aws-ecs](https://github.com/anrim/terraform-aws-ecs/blob/master/main.tf)
3. [terraform-aws-modules/ecs/](https://registry.terraform.io/modules/terraform-aws-modules/ecs/aws/3.1.0/examples/complete-ecs)
# CI/CD Pipeline Proposal for Hello-you-API

## Overview

This document describes the current Continuous Integration (CI) and Continuous Delivery (CD) process.
It covers code quality checks, security scanning, Docker image builds, and ECS deployments.

At the end, we discuss the **AWS CodeDeploy** integration to the current pipeline. Enabling a controlled rollout and
easier Rollback strategies.

---

## Current CI Pipeline

### 1. Code Quality and Testing

* **Linting:**
    * Tools: `pylint`, `flake8`
    * Ensures consistent coding style and detects potential issues.

* **Unit Tests with Coverage:**
    * Framework: `pytest`
    * Generates coverage reports uploaded as artifacts.

* **Security Scans:**
    * Tool: `bandit`
    * Detects common Python security vulnerabilities.

📄 **File:** [ci.yml](.github/workflows/ci.yml)
✔️ Triggered on every `push` or `pull_request` to `main`.

---

### 2. Docker Image Build and Publishing

* Builds and pushes a Docker image to **GitHub Container Registry (GHCR)**.
* Tagging:
    * `latest` (for `main` branch)
    * `v*.*.*` (for tagged releases)
* ECS currently pulls the image directly (defined in Terraform).

📄 **File:** [docker-image.yml](.github/workflows/docker-image.yml)
✔️ Triggered on every `push` to `main` and on tagged releases.

---

## Current Deployment (Direct ECS)
    `[In-progress]` This is a temporary deployment trigger, until CodeDeploy work is complete. 
* The ECS Fargate task definition references the image hosted on GHCR.
* Deployment is triggered manually via Terraform updates.
* AWS CLI step (`aws ecs update-service --force-new-deployment`) is prepared but currently commented out in CI.

---

## Proposed Improvement: CodeDeploy Integration

### Motivation

* Enable **zero-downtime deployments** with rolling updates.
* Improve **rollback safety** in case of deployment issues.
* Automate ECS service updates without manual `terraform apply` or `aws-cli ecs update-service --force-new-deployment`

Here’s an updated **README** section that includes:

* A **detailed CodeDeploy proposal description**
* A **CI GitHub Actions example** to trigger deployments
* A **Terraform template** showing how to set up CodeDeploy for ECS

---

# CI/CD Pipeline Proposal for Hello0you API

## Overview

This document describes the current Continuous Integration (CI) and Continuous Delivery (CD) process for the Hello0you API project. It covers code quality checks, security scanning, Docker image builds, and ECS deployments. Additionally, it proposes integrating **AWS CodeDeploy** to improve deployment reliability and enable advanced rollout strategies (Blue/Green deployments).

---

## Current CI Pipeline

### 1. Code Quality and Testing

* **Linting:** `pylint`, `flake8`
* **Unit Tests:** `pytest` with coverage reports
* **Security Scans:** `bandit` for Python security vulnerabilities

📄 **File:** `.github/workflows/ci.yml`
✔️ Triggered on every `push` or `pull_request` to `main`.

### 2. Docker Image Build and Publishing

* Builds and pushes a Docker image to **GitHub Container Registry (GHCR)**.
* Tags:

  * `latest` (for main branch)
  * `v*.*.*` (for tagged releases)
* ECS currently references the image directly via Terraform.

📄 **File:** `.github/workflows/docker-image.yml`
✔️ Triggered on every `push` to `main` and on tagged releases.

---

## Proposed Improvement: CodeDeploy Integration

### Why CodeDeploy?

* **Zero Downtime:** Blue/Green deployment ensures current tasks keep serving traffic during updates.
* **Automatic Rollback:** Failed deployments automatically revert to the last stable version.
* **Traffic Shifting:** Gradual rollout (canary or linear) reduces release risk.
* **Automation:** Removes the need for manual ECS updates via Terraform or AWS CLI.

---

### How It Works

1. **Terraform Setup**

   * Creates a **CodeDeploy Application** and **Deployment Group** targeting your ECS service.
   * Configures an **Application Load Balancer (ALB)** with two target groups:

     * **Blue** (current running tasks)
     * **Green** (new task set for the deployment)
   * ECS service is configured to allow multiple task sets for Blue/Green strategy.

2. **CI/CD Deployment**

   * CI builds a new image and registers a new ECS task definition revision.
   * GitHub Actions triggers CodeDeploy using:
        `Replace the aws ecs update-service --force-new-deployment action`
     ```bash
     aws deploy create-deployment \
       --application-name hello-you-api-app \
       --deployment-group-name hello-you-api-dg \
       --revision file://appspec.json
     ```
   * CodeDeploy:

     * Creates a **Green task set** with the new revision.
     * Shifts traffic from Blue → Green (linear or canary).
     * Runs health checks.
     * Automatically rolls back if deployment fails.
     * Finalizes by deleting Blue task set if/when successful.

---

### Example CI Job (Triggering CodeDeploy)

```yaml
name: Deploy to ECS via CodeDeploy
on:
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        
      - name: Register new ECS task definition
        run: |
          aws ecs register-task-definition \
            --cli-input-json file://ecs-task-def.json

      - name: Trigger CodeDeploy deployment
        run: |
          aws deploy create-deployment \
            --application-name hello-you-api-app \
            --deployment-group-name hello-you-api-dg \
            --revision file://appspec.json
```

### Terraform CodeDeploy Sample

```hcl
resource "aws_codedeploy_app" "hello_api" {
  name = "hello-you-api-app"
  compute_platform = "ECS"
}

resource "aws_codedeploy_deployment_group" "hello_api" {
  app_name              = aws_codedeploy_app.hello_api.name
  deployment_group_name = "hello-you-api-dg"
  service_role_arn      = aws_iam_role.codedeploy_role.arn
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"

  blue_green_deployment_config {
    terminate_blue_tasks_on_deployment_success {
      action = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.hello_api.name
    service_name = aws_ecs_service.hello_api.name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [aws_lb_listener.prod.arn]
      }
      test_traffic_route {
        listener_arns = [aws_lb_listener.test.arn]
      }
      target_groups {
        name = aws_lb_target_group.blue.name
      }
      target_groups {
        name = aws_lb_target_group.green.name
      }
    }
  }
}

resource "aws_lb_target_group" "blue" {
  name     = "hello-api-blue"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
}

resource "aws_lb_target_group" "green" {
  name     = "hello-api-green"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
}
```

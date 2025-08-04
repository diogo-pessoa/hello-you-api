# System Architecture Diagram

## High-level architecture overview

![Hello-you-Api-Diagram.jpeg](images/Hello-you-Api-Diagram.jpeg)

AWS deployment diagram ECS Fargate [Terraform](../Terraform) folder deploys the following Resources to create the
resources as the diagram above.

This Deployment is a **single Region Deployment**. For a proposal on Multi-region deployment,
see: [system_diagram_multi-region.md](system_diagram_multi-region.md)

### Network

- VPC [vpc.tf](../Terraform/vpc.tf)
    - _Nat Gateway_ proxy request between Public/Private Subnets
    - _Internet Gateway_
    - _Route Tables_
    - **Private Subnet**
        - [_RDS_](../Terraform/rds.tf)
            - Master DB Instance PostGresSQL
            - RDS Read Replica (Act as back-up in case of failure)
        - [_ECS Fargate Cluster_](../Terraform/ecs-fargate.tf)
            - Task Definition (Horizontally scalable)
    - **Public subnet**
        - [Bastion Host](../Terraform/bastion.tf)
            - Allows Admin access in exceptional cases (break Glass policy). If an SRE needs access to RDS or other
              internal (Private Subnet resources); The bastion host act as a single access point.
            - Bastion Security Group Allow Inbound is limited to a single IP x.x.x.x/32
        - [Application Load Balancer](../Terraform/alb.tf)

### Logs, Metrics, Alerts & Scaling Policies

- [**ECS**](../Terraform/ecs-fargate.tf)
    - CPU Usage Auto-Scaling Triggers Up/down
    - Memory Average Memory Utilization Triggers Up/down
    - Enabled CloudWatch Logs
- [**RDS**](../Terraform/rds.tf)
    - RDS Master cpu high usage
    - RDS Replica Lag alerts
    - [Nice to have ] Set up slow query low monitoring to catch performance issues early
    - Enabled CloudWatch Logs

### Secret Management

#### [secrets.tf](../Terraform/secrets.tf)

All resource secrets and keys are created when Terraform runs. Secrets are Stored in AWS Secrets Manager.

- _github_token_
    - the application docker image is hosted in Github container registry. Terraform loads the variable and creates the
      Secret at runtime
- RDS application credentials (user/password)
    - _username_ is declared as a Terraform Variable
    - _password_ is a Terraform randomized string ([random_password.db_password](../Terraform/secrets.tf#2)), which is
      saved as a Secret Manager parameter (ssm parameter). That is, a secure environment variable later used by ECS to
      load DB
      credentials to the application
- _Flask app secret key_ same as RDS db password. randomly generated and passed as a ssm parameter.

### IAM

#### [iam.tf](../Terraform/iam.tf)

The policies created by this design, aim for the least privilege pattern. New policies are created and attached to their
respective roles according to their scope.

## Proposed Multi-region Deployment

This proposed approach aims to add support for a cross-region fail-over design. If region a fails, we leverage Route53
to redirect traffic to region b.

Although, cost and other aspects need be considered to decide on the fail-over plan. Let's assume a Pilot-light
strategy. the whole infrastructure is deployed in region b, with minimum resource allocation.

A critical resource for this design is a cross-regional read-replica. In case, of a complete failure in Region A (RDS
unreachable). The RDS in region B can be promoted and act as the new master. Note that, in this approach, The App can
and should continue running in Region b, even after recovery.

In case of partial interruptions. Ex: ECS Down, RDS Master still available, ECS in region b (fail-over) can scale-up and take
the load. (Route 53 re-routes traffic if region A is unresponsive.). All the while still writting to Master RDS instance
in Region A.

_This proposal, requires extra resources not yet implemented in this Terraform templates._ 


![hello-you-api-diagram-fail-over.jpeg](images/hello-you-api-diagram-fail-over.jpeg)


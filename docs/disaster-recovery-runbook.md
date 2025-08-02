# Disaster Recovery Runbook

## Overview
This runbook covers the disaster recovery procedures for the ECS Fargate application with PostgreSQL RDS Master/Read Replica setup.

## Architecture
- **Master Database**: Primary PostgreSQL instance handling all writes
- **Read Replica**: Secondary PostgreSQL instance for read operations and DR
- **ECS Auto Scaling**: Automatically scales between 1-6 tasks based on CPU/Memory

## Monitoring & Alerts

### Key Metrics to Monitor
1. **RDS Master CPU** > 85% for 10 minutes
2. **RDS Replica Lag** > 5 minutes
3. **ECS Service CPU** > 85% for 15 minutes
4. **ECS Task Count** - should auto-scale between 1-6

### CloudWatch Dashboards
- Monitor both RDS instances health
- Track ECS service scaling events
- Watch application response times

## Disaster Scenarios & Recovery

### Scenario 1: RDS Master Failure
**Detection**: Master database becomes unavailable
**Recovery Steps**:
1. Promote read replica to master:
   ```bash
   aws rds promote-read-replica --db-instance-identifier your-app-dev-db-replica
   ```
2. Update application configuration to point to new master
3. Create new read replica from the promoted instance

**Estimated Recovery Time**: 5-15 minutes

### Scenario 2: High Load / ECS Scaling
**Detection**: CPU/Memory > 70-80%
**Automatic Response**: 
- ECS will automatically scale from 1 to max 6 tasks
- Target tracking will maintain 70% CPU, 80% Memory

**Manual Intervention** (if needed):
```bash
aws ecs update-service --cluster your-cluster --service your-service --desired-count 8
```

### Scenario 3: Application Container Issues
**Detection**: Tasks failing health checks
**Recovery**:
1. Check CloudWatch logs for application errors
2. Roll back to previous task definition if needed:
   ```bash
   aws ecs update-service --cluster your-cluster --service your-service --task-definition previous-revision
   ```

## Connection Strings

### Application Configuration
Your application should be configured to use:
- **Write Operations**: Master endpoint
- **Read Operations**: Read replica endpoint (optional optimization)

### Environment Variables
```bash
# Master (for writes)
DATABASE_URL=postgresql://username:password@master-endpoint:5432/helloworld

# Read Replica (for reads - optional)
DATABASE_READ_URL=postgresql://username:password@replica-endpoint:5432/helloworld
```

## Testing DR Procedures

### Monthly DR Test
1. **Simulate Master Failure**:
   - Stop master instance
   - Promote replica
   - Verify application connectivity
   - Restore master as new replica

2. **Load Testing**:
   - Generate traffic to trigger auto-scaling
   - Verify scaling behavior
   - Monitor scaling metrics

### Validation Checklist
- [ ] Read replica lag < 5 minutes
- [ ] Auto-scaling triggers at expected thresholds
- [ ] Application connects to promoted replica
- [ ] Backup restoration works
- [ ] CloudWatch alarms are functional

## Recovery Time Objectives (RTO)
- **RDS Failover**: 5-15 minutes
- **ECS Scaling**: 2-5 minutes
- **Complete Service Restoration**: < 20 minutes

## Recovery Point Objectives (RPO)
- **Data Loss Tolerance**: < 5 minutes (based on replica lag)
- **Backup Retention**: 7 days

## Emergency Contacts
- AWS Support: [Your support plan]
- DevOps Team: [Contact information]
- Database Administrator: [Contact information]

## Post-Incident Actions
1. Review incident timeline
2. Update runbook based on lessons learned
3. Test any new procedures
4. Update monitoring thresholds if needed
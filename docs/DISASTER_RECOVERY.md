# Disaster Recovery Runbook

## Overview
This document provides step-by-step procedures for recovering from various disaster scenarios affecting the AWS Control Tower infrastructure.

## Table of Contents
1. [Emergency Contacts](#emergency-contacts)
2. [RTO/RPO Definitions](#rtorpo-definitions)
3. [Disaster Scenarios](#disaster-scenarios)
4. [Recovery Procedures](#recovery-procedures)
5. [Testing Schedule](#testing-schedule)
6. [Post-Recovery Actions](#post-recovery-actions)

---

## Emergency Contacts

### Primary Contacts
| Role | Name | Phone | Email | Availability |
|------|------|-------|-------|--------------|
| Infrastructure Lead | [NAME] | [PHONE] | [EMAIL] | 24/7 |
| Security Lead | [NAME] | [PHONE] | [EMAIL] | 24/7 |
| AWS TAM | [NAME] | [PHONE] | [EMAIL] | Business Hours |
| On-Call Engineer | [ROTATION] | [PHONE] | [EMAIL] | 24/7 |

### Escalation Path
1. On-Call Engineer (Response: 15 minutes)
2. Infrastructure Lead (Response: 30 minutes)
3. CTO/VP Engineering (Response: 1 hour)

### External Contacts
- AWS Support: 1-877-AWS-SUPPORT
- AWS Premium Support Case: https://console.aws.amazon.com/support/

---

## RTO/RPO Definitions

### Recovery Time Objective (RTO)
Maximum acceptable time to restore service after a disaster.

| Component | RTO | Priority |
|-----------|-----|----------|
| Control Tower | 4 hours | Critical |
| Terraform State | 1 hour | Critical |
| Security Services | 2 hours | Critical |
| Networking | 2 hours | High |
| Logging | 4 hours | High |

### Recovery Point Objective (RPO)
Maximum acceptable data loss measured in time.

| Component | RPO | Backup Frequency |
|-----------|-----|------------------|
| Terraform State | 1 hour | Continuous (S3 versioning) |
| CloudTrail Logs | 15 minutes | Real-time |
| Config Snapshots | 24 hours | Daily |
| Security Hub Findings | 1 hour | Continuous |

---

## Disaster Scenarios

### Scenario 1: Terraform State File Corruption
**Severity:** Critical  
**Impact:** Cannot manage infrastructure  
**RTO:** 1 hour  
**RPO:** 1 hour

### Scenario 2: Accidental Resource Deletion
**Severity:** High  
**Impact:** Service disruption  
**RTO:** 2-4 hours  
**RPO:** Varies by resource

### Scenario 3: AWS Account Compromise
**Severity:** Critical  
**Impact:** Security breach, data loss  
**RTO:** 4-8 hours  
**RPO:** Varies

### Scenario 4: Region Failure
**Severity:** Critical  
**Impact:** Complete service outage  
**RTO:** 8-12 hours  
**RPO:** 1 hour

### Scenario 5: Terraform State Lock Stuck
**Severity:** Medium  
**Impact:** Cannot deploy changes  
**RTO:** 30 minutes  
**RPO:** N/A

---

## Recovery Procedures

### Procedure 1: Recover Terraform State File

#### Symptoms
- `terraform plan` fails with state errors
- State file corruption detected
- Cannot read state file

#### Prerequisites
- Access to AWS management account
- Terraform CLI installed
- AWS CLI configured

#### Steps

1. **Assess the Situation**
   ```bash
   # Check current state
   terraform state list
   
   # Verify state file exists
   aws s3 ls s3://[STATE-BUCKET]/terraform.tfstate
   ```

2. **Retrieve Latest Backup**
   ```bash
   # List available backups
   aws s3 ls s3://[STATE-BUCKET]/backups/ --recursive
   
   # Download latest backup
   aws s3 cp s3://[STATE-BUCKET]/backups/terraform.tfstate.[TIMESTAMP] \
     ./terraform.tfstate.backup
   ```

3. **Verify Backup Integrity**
   ```bash
   # Check backup is valid JSON
   cat terraform.tfstate.backup | jq . > /dev/null
   
   # Verify terraform version
   cat terraform.tfstate.backup | jq -r '.terraform_version'
   ```

4. **Restore State File**
   ```bash
   # Push backup to S3
   terraform state push terraform.tfstate.backup
   
   # Verify restoration
   terraform state list
   ```

5. **Validate Infrastructure**
   ```bash
   # Run plan to check for drift
   terraform plan
   
   # If drift detected, review and apply
   terraform apply
   ```

6. **Document Recovery**
   - Record timestamp of failure
   - Document root cause
   - Update runbook if needed

#### Rollback
If restoration fails:
```bash
# Restore previous version from S3 versioning
aws s3api list-object-versions \
  --bucket [STATE-BUCKET] \
  --prefix terraform.tfstate

# Download specific version
aws s3api get-object \
  --bucket [STATE-BUCKET] \
  --key terraform.tfstate \
  --version-id [VERSION-ID] \
  terraform.tfstate.restored
```

---

### Procedure 2: Recover from Accidental Deletion

#### Symptoms
- Resources missing from AWS console
- Terraform detects resources need to be created
- Alerts for missing resources

#### Steps

1. **Identify Deleted Resources**
   ```bash
   # Check CloudTrail for deletion events
   aws cloudtrail lookup-events \
     --lookup-attributes AttributeKey=EventName,AttributeValue=Delete* \
     --max-results 50
   
   # Run terraform plan to see what's missing
   terraform plan
   ```

2. **Determine Recovery Method**
   
   **Option A: Restore from Terraform**
   ```bash
   # If resources can be recreated
   terraform apply
   ```
   
   **Option B: Import Existing Resources**
   ```bash
   # If resources still exist but state is wrong
   terraform import [RESOURCE_ADDRESS] [RESOURCE_ID]
   ```
   
   **Option C: Restore from Backup**
   ```bash
   # For critical data (S3, databases)
   # Follow AWS service-specific restore procedures
   ```

3. **Verify Recovery**
   ```bash
   # Check all resources exist
   terraform state list
   
   # Verify no drift
   terraform plan
   
   # Test functionality
   # [Service-specific tests]
   ```

4. **Implement Preventive Measures**
   - Review IAM permissions
   - Enable MFA delete on S3 buckets
   - Add resource deletion protection
   - Update SCPs if needed

---

### Procedure 3: Respond to Account Compromise

#### Symptoms
- Unauthorized API calls in CloudTrail
- GuardDuty findings
- Unexpected resource creation
- Unusual billing activity

#### Immediate Actions (First 15 Minutes)

1. **Isolate the Account**
   ```bash
   # Attach deny-all SCP to affected OU
   aws organizations attach-policy \
     --policy-id [DENY-ALL-POLICY-ID] \
     --target-id [OU-ID]
   ```

2. **Rotate Credentials**
   ```bash
   # Disable all IAM users
   for user in $(aws iam list-users --query 'Users[].UserName' --output text); do
     aws iam update-login-profile --user-name $user --password-reset-required
   done
   
   # Delete access keys
   for user in $(aws iam list-users --query 'Users[].UserName' --output text); do
     for key in $(aws iam list-access-keys --user-name $user --query 'AccessKeyMetadata[].AccessKeyId' --output text); do
       aws iam delete-access-key --user-name $user --access-key-id $key
     done
   done
   ```

3. **Enable CloudTrail Logging**
   ```bash
   # Ensure CloudTrail is enabled and logging
   aws cloudtrail get-trail-status --name [TRAIL-NAME]
   ```

#### Investigation (First Hour)

4. **Analyze CloudTrail Logs**
   ```bash
   # Find unauthorized activities
   aws cloudtrail lookup-events \
     --start-time [INCIDENT-TIME] \
     --lookup-attributes AttributeKey=EventName,AttributeValue=RunInstances
   ```

5. **Check for Backdoors**
   - Review IAM users and roles
   - Check for unauthorized EC2 instances
   - Review security group rules
   - Check for unauthorized Lambda functions

6. **Document Evidence**
   - Save CloudTrail logs
   - Screenshot GuardDuty findings
   - Record timeline of events

#### Recovery (Hours 2-4)

7. **Remove Malicious Resources**
   ```bash
   # Terminate unauthorized instances
   aws ec2 terminate-instances --instance-ids [INSTANCE-IDS]
   
   # Delete unauthorized IAM users
   aws iam delete-user --user-name [MALICIOUS-USER]
   ```

8. **Restore Clean State**
   ```bash
   # Restore from known-good state backup
   terraform state push backups/terraform.tfstate.[CLEAN-TIMESTAMP]
   
   # Apply clean configuration
   terraform apply
   ```

9. **Re-enable Access**
   ```bash
   # Remove deny-all SCP
   aws organizations detach-policy \
     --policy-id [DENY-ALL-POLICY-ID] \
     --target-id [OU-ID]
   ```

#### Post-Incident (Days 1-7)

10. **Conduct Post-Mortem**
    - Root cause analysis
    - Timeline of events
    - Lessons learned
    - Action items

11. **Implement Improvements**
    - Update security policies
    - Enhance monitoring
    - Conduct security training

---

### Procedure 4: Recover from Region Failure

#### Symptoms
- AWS region unavailable
- Services not responding
- AWS Health Dashboard shows region issues

#### Steps

1. **Verify Region Status**
   ```bash
   # Check AWS Health Dashboard
   aws health describe-events --filter eventTypeCategories=issue
   
   # Check service status
   curl https://status.aws.amazon.com/
   ```

2. **Assess Impact**
   - Identify affected resources
   - Determine if failover needed
   - Check if data is replicated

3. **Failover to DR Region** (if configured)
   ```bash
   # Update backend configuration
   terraform init -backend-config="region=ap-southeast-1"
   
   # Restore state from replica
   aws s3 cp s3://[REPLICA-BUCKET]/terraform.tfstate ./
   
   # Deploy to DR region
   terraform apply -var="home_region=ap-southeast-1"
   ```

4. **Update DNS/Routing**
   - Update Route 53 records
   - Update load balancer targets
   - Notify users of region change

5. **Monitor Recovery**
   - Watch AWS Health Dashboard
   - Monitor application metrics
   - Check for errors

6. **Failback** (when primary region recovers)
   ```bash
   # Sync data back to primary region
   # Update DNS back to primary
   # Verify functionality
   ```

---

### Procedure 5: Clear Stuck Terraform Lock

#### Symptoms
- `terraform plan` fails with lock error
- Error message: "Error acquiring the state lock"
- Lock persists after process termination

#### Steps

1. **Verify Lock Status**
   ```bash
   # Check S3 for lock file
   aws s3 ls s3://[STATE-BUCKET]/.terraform.lock.info
   ```

2. **Identify Lock Owner**
   ```bash
   # Download lock file
   aws s3 cp s3://[STATE-BUCKET]/.terraform.lock.info ./
   
   # View lock details
   cat .terraform.lock.info | jq .
   ```

3. **Verify Process is Dead**
   - Check if Terraform process is still running
   - Check CI/CD pipeline status
   - Confirm no one else is deploying

4. **Force Unlock**
   ```bash
   # Get lock ID from error message or lock file
   terraform force-unlock [LOCK-ID]
   ```

5. **Verify Unlock**
   ```bash
   # Try running plan
   terraform plan
   ```

#### Prevention
- Use shorter lock timeouts
- Implement lock monitoring
- Add automatic unlock after timeout

---

## Testing Schedule

### Quarterly Tests
- [ ] State file restoration
- [ ] Backup integrity verification
- [ ] DR region failover (if configured)

### Annual Tests
- [ ] Full disaster recovery drill
- [ ] Account compromise simulation
- [ ] Region failure simulation

### After Each Test
- Update runbook with findings
- Document time to recover
- Identify improvements

---

## Post-Recovery Actions

### Immediate (Within 24 Hours)
1. Verify all services operational
2. Check for data loss
3. Review monitoring alerts
4. Notify stakeholders

### Short-term (Within 1 Week)
1. Conduct post-mortem meeting
2. Document incident timeline
3. Update runbook
4. Implement quick fixes

### Long-term (Within 1 Month)
1. Implement preventive measures
2. Update disaster recovery plan
3. Conduct training
4. Review and update RTO/RPO

---

## Appendix

### A. Useful Commands

```bash
# Check AWS account
aws sts get-caller-identity

# List all resources
aws resourcegroupstaggingapi get-resources

# Check CloudTrail events
aws cloudtrail lookup-events --max-results 50

# List S3 buckets
aws s3 ls

# Check Terraform version
terraform version

# Validate Terraform configuration
terraform validate

# Show Terraform state
terraform show
```

### B. Important ARNs and IDs

```
Root OU ID: [OU-ID]
Management Account ID: [ACCOUNT-ID]
State Bucket: [BUCKET-NAME]
KMS Key ID: [KEY-ID]
CloudTrail Name: [TRAIL-NAME]
```

### C. Backup Locations

```
Primary State: s3://[STATE-BUCKET]/terraform.tfstate
State Backups: s3://[STATE-BUCKET]/backups/
State Replica: s3://[REPLICA-BUCKET]/terraform.tfstate
CloudTrail Logs: s3://[LOGS-BUCKET]/cloudtrail/
Config Snapshots: s3://[LOGS-BUCKET]/config/
```

### D. Recovery Time Tracking

| Date | Scenario | Time to Detect | Time to Recover | Notes |
|------|----------|----------------|-----------------|-------|
| | | | | |

---

## Document Control

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2024-01-01 | [NAME] | Initial version |

**Last Reviewed:** [DATE]  
**Next Review:** [DATE + 6 months]  
**Owner:** Infrastructure Team

# Enterprise Security and Logging

## Overview

This Control Tower deployment includes enterprise-grade security and logging capabilities designed to meet compliance requirements for SOC 2, ISO 27001, PCI DSS, and other frameworks.

## Security Architecture

### Defense in Depth

```
┌─────────────────────────────────────────────────────────────┐
│                    Prevention Layer                          │
│  • Service Control Policies (SCPs)                          │
│  • IAM Policies and Permission Boundaries                   │
│  • Security Groups and NACLs                                │
│  • KMS Encryption (at rest and in transit)                  │
└─────────────────────────────────────────────────────────────┘
                            │
┌─────────────────────────────────────────────────────────────┐
│                    Detection Layer                           │
│  • GuardDuty (Threat Detection)                             │
│  • Security Hub (Compliance Monitoring)                     │
│  • AWS Config (Configuration Compliance)                    │
│  • CloudTrail (API Auditing)                                │
│  • Access Analyzer (IAM Analysis)                           │
│  • Macie (Data Discovery - Optional)                        │
└─────────────────────────────────────────────────────────────┘
                            │
┌─────────────────────────────────────────────────────────────┐
│                    Response Layer                            │
│  • CloudWatch Alarms (Real-time Alerts)                     │
│  • SNS Notifications (Multi-tier)                           │
│  • EventBridge Rules (Automated Response)                   │
│  • Lambda Functions (Auto-remediation)                      │
└─────────────────────────────────────────────────────────────┘
```

## Encryption

### KMS Key Management

**Master Key Features:**
- Automatic key rotation enabled
- 30-day deletion window
- Multi-region support (optional)
- Comprehensive key policy for AWS services

**Encrypted Resources:**
- S3 buckets (log archive, access logs)
- CloudWatch Logs
- SNS topics
- CloudTrail logs
- EBS volumes (via SCP)

**Key Policy Permissions:**
- CloudTrail encryption/decryption
- CloudWatch Logs encryption
- S3 server-side encryption
- AWS Config encryption
- SNS encryption

### Encryption Standards

- **At Rest**: AES-256 with KMS
- **In Transit**: TLS 1.2+ enforced
- **Key Rotation**: Automatic annual rotation
- **Access Control**: Least privilege via key policies

## Logging Architecture

### Centralized Logging

```
┌──────────────────────────────────────────────────────────┐
│                  All AWS Accounts                         │
│                                                           │
│  CloudTrail ──────────┐                                  │
│  VPC Flow Logs ───────┼──────> S3 Log Archive Bucket    │
│  AWS Config ──────────┤        (Encrypted, Versioned)    │
│  Application Logs ────┘                                  │
│                                                           │
│  CloudTrail ──────────> CloudWatch Logs                  │
│                         (Real-time Analysis)             │
└──────────────────────────────────────────────────────────┘
                            │
                            ▼
┌──────────────────────────────────────────────────────────┐
│              Log Lifecycle Management                     │
│                                                           │
│  0-90 days:    S3 Standard (Hot)                         │
│  90-365 days:  S3 Glacier (Warm)                         │
│  365+ days:    S3 Deep Archive (Cold)                    │
│  2555 days:    Deletion (7 years retention)              │
└──────────────────────────────────────────────────────────┘
```

### CloudTrail Configuration

**Organization Trail Features:**
- Multi-region enabled
- Global service events included
- Log file validation enabled
- Data events for S3 and Lambda
- Insights for API call/error rate anomalies
- CloudWatch Logs integration

**Data Events Captured:**
- All S3 object-level operations
- All Lambda function invocations
- Management events across all services

### S3 Log Bucket Security

**Protection Measures:**
- Public access blocked (all settings)
- Versioning enabled
- MFA delete (recommended)
- Bucket policy enforces:
  - Encrypted uploads only
  - TLS in transit only
  - Service-specific access
- Access logging to separate bucket
- Object lock (optional for compliance)

## Threat Detection

### Amazon GuardDuty

**Configuration:**
- Finding frequency: 15 minutes
- Data sources enabled:
  - VPC Flow Logs
  - DNS logs
  - CloudTrail events
  - S3 data events
  - Kubernetes audit logs
  - EBS malware scanning

**Automated Response:**
- High/Critical findings → SNS notification
- EventBridge integration for automation
- Security Hub aggregation

**Finding Types Monitored:**
- Reconnaissance attempts
- Instance compromise
- Account compromise
- Bucket compromise
- Cryptocurrency mining
- Malware detection

### AWS Security Hub

**Standards Enabled:**
1. **CIS AWS Foundations Benchmark v1.4.0**
   - 43 automated checks
   - Industry best practices
   - Compliance scoring

2. **AWS Foundational Security Best Practices**
   - 200+ automated checks
   - AWS-recommended controls
   - Continuous monitoring

3. **PCI DSS v3.2.1** (Optional)
   - Payment card industry standards
   - 40+ compliance checks
   - Cardholder data protection

**Security Hub Features:**
- Centralized findings dashboard
- Automated compliance checks
- Finding aggregation from:
  - GuardDuty
  - Inspector
  - Macie
  - IAM Access Analyzer
  - Firewall Manager
  - Third-party tools

### AWS Config

**Configuration Recording:**
- All resource types
- Global resources included
- Snapshot frequency: 24 hours
- Change notifications via SNS

**Compliance Rules (10 Managed Rules):**

1. **encrypted-volumes**
   - Ensures EBS volumes are encrypted
   - Severity: High

2. **root-account-mfa-enabled**
   - Verifies root MFA is enabled
   - Severity: Critical

3. **iam-password-policy**
   - Enforces strong password requirements:
     - Minimum 14 characters
     - Uppercase, lowercase, numbers, symbols
     - 24 password history
     - 90-day max age
   - Severity: High

4. **s3-bucket-public-read-prohibited**
   - Prevents public read access
   - Severity: Critical

5. **s3-bucket-public-write-prohibited**
   - Prevents public write access
   - Severity: Critical

6. **s3-bucket-ssl-requests-only**
   - Enforces HTTPS for S3 access
   - Severity: High

7. **s3-bucket-versioning-enabled**
   - Ensures versioning for data protection
   - Severity: Medium

8. **cloudtrail-enabled**
   - Verifies CloudTrail is active
   - Severity: Critical

9. **rds-storage-encrypted**
   - Ensures RDS encryption
   - Severity: High

10. **vpc-flow-logs-enabled**
    - Verifies VPC Flow Logs
    - Severity: Medium

**Remediation:**
- Manual remediation workflows
- Automated remediation (via Lambda)
- Compliance timeline tracking

### IAM Access Analyzer

**Features:**
- Organization-wide analysis
- External access detection
- Policy validation
- Unused access identification

**Findings:**
- S3 buckets accessible externally
- IAM roles assumable by external accounts
- KMS keys shared externally
- Lambda functions with external access
- SQS queues with cross-account access

### Amazon Macie (Optional)

**Data Discovery:**
- Sensitive data identification
- PII detection
- Financial data discovery
- Credential scanning

**Use Cases:**
- GDPR compliance
- HIPAA compliance
- Data classification
- Data loss prevention

## CloudWatch Monitoring

### Metric Filters and Alarms

**1. Unauthorized API Calls**
- **Pattern**: AccessDenied or UnauthorizedOperation
- **Threshold**: 5 calls in 5 minutes
- **Action**: SNS notification to security team
- **Severity**: High

**2. Root Account Usage**
- **Pattern**: Root user activity (non-service events)
- **Threshold**: 1 occurrence
- **Action**: Immediate SNS notification
- **Severity**: Critical

**3. IAM Policy Changes**
- **Pattern**: Policy create/delete/modify operations
- **Threshold**: 1 change
- **Action**: SNS notification
- **Severity**: High

**4. Console Sign-in Failures**
- **Pattern**: Failed authentication attempts
- **Threshold**: 3 failures in 5 minutes
- **Action**: SNS notification
- **Severity**: Medium

**5. VPC Changes**
- **Pattern**: VPC create/delete/modify operations
- **Threshold**: 1 change
- **Action**: SNS notification
- **Severity**: Medium

**6. Security Group Changes**
- **Pattern**: Security group rule modifications
- **Threshold**: 5 changes in 5 minutes
- **Action**: SNS notification
- **Severity**: Medium

### CloudWatch Logs

**Log Groups:**
- `/aws/cloudtrail/organization-trail` - CloudTrail events
- `/aws/controltower/control-tower` - Control Tower events
- Application-specific log groups

**Retention:**
- CloudWatch Logs: 365 days
- S3 Archive: 7 years (2555 days)

**Features:**
- Log Insights for querying
- Metric filters for alerting
- Subscription filters for streaming
- KMS encryption

## Notification Architecture

### Two-Tier SNS Topics

**1. Security Notifications (High Priority)**
- GuardDuty high/critical findings
- Security Hub critical findings
- Root account usage
- IAM policy changes
- Config compliance violations
- Access Analyzer findings

**Recipients:**
- Security team
- SOC team
- CISO (optional)

**2. Operational Notifications (Normal Priority)**
- Control Tower lifecycle events
- VPC changes
- Security group changes
- Config snapshot delivery
- General operational alerts

**Recipients:**
- Platform team
- Cloud operations team
- DevOps team

### SNS Security

- KMS encryption enabled
- Access policies restrict publishers
- Email subscriptions require confirmation
- HTTPS delivery for webhooks
- Dead letter queue for failed deliveries

## EventBridge Automation

### Security Event Rules

**1. GuardDuty Findings (Severity 7-10)**
```json
{
  "source": ["aws.guardduty"],
  "detail-type": ["GuardDuty Finding"],
  "detail": {
    "severity": [7, 8, 9, 10]
  }
}
```
**Action**: SNS notification

**2. Security Hub Critical/High Findings**
```json
{
  "source": ["aws.securityhub"],
  "detail-type": ["Security Hub Findings - Imported"],
  "detail": {
    "findings": {
      "Severity": {
        "Label": ["CRITICAL", "HIGH"]
      }
    }
  }
}
```
**Action**: SNS notification

**3. Config Compliance Changes**
```json
{
  "source": ["aws.config"],
  "detail-type": ["Config Rules Compliance Change"],
  "detail": {
    "newEvaluationResult": {
      "complianceType": ["NON_COMPLIANT"]
    }
  }
}
```
**Action**: SNS notification

**4. Control Tower Lifecycle Events**
```json
{
  "source": ["aws.controltower"],
  "detail-type": ["AWS Service Event via CloudTrail"]
}
```
**Action**: SNS notification

## Compliance Mapping

### SOC 2

| Control | Implementation |
|---------|---------------|
| CC6.1 - Logical Access | IAM, SCPs, MFA enforcement |
| CC6.6 - Encryption | KMS encryption for all data |
| CC7.2 - Monitoring | CloudTrail, GuardDuty, Security Hub |
| CC7.3 - Threat Detection | GuardDuty, Config Rules |
| CC7.4 - Incident Response | SNS notifications, EventBridge |

### CIS AWS Foundations Benchmark

| Section | Controls | Automated |
|---------|----------|-----------|
| 1.0 Identity and Access Management | 22 | 18 |
| 2.0 Storage | 9 | 9 |
| 3.0 Logging | 11 | 11 |
| 4.0 Monitoring | 15 | 15 |
| 5.0 Networking | 5 | 3 |

**Compliance Score**: Tracked in Security Hub

### PCI DSS (Optional)

| Requirement | Implementation |
|-------------|---------------|
| 2.1 - Default passwords | IAM password policy |
| 3.4 - Encryption | KMS encryption |
| 10.1 - Audit trails | CloudTrail |
| 10.5 - Log protection | S3 bucket policies, versioning |
| 10.7 - Log retention | 7-year retention |

## Security Operations

### Daily Tasks

1. **Review Security Hub Dashboard**
   - Check compliance scores
   - Review new findings
   - Verify remediation status

2. **Monitor GuardDuty Findings**
   - Investigate high/critical findings
   - Update threat intelligence
   - Tune detection rules

3. **Check CloudWatch Alarms**
   - Review triggered alarms
   - Investigate anomalies
   - Update thresholds if needed

### Weekly Tasks

1. **Config Compliance Review**
   - Review non-compliant resources
   - Track remediation progress
   - Update Config rules

2. **Access Analyzer Review**
   - Review external access findings
   - Validate legitimate access
   - Revoke unnecessary permissions

3. **Log Analysis**
   - CloudWatch Logs Insights queries
   - Trend analysis
   - Anomaly detection

### Monthly Tasks

1. **Security Posture Assessment**
   - Security Hub compliance trends
   - GuardDuty finding patterns
   - Config rule effectiveness

2. **Access Review**
   - IAM user/role review
   - Permission boundary validation
   - Unused credential cleanup

3. **Incident Response Testing**
   - Tabletop exercises
   - Runbook validation
   - Team training

### Quarterly Tasks

1. **Compliance Audit**
   - Generate compliance reports
   - Evidence collection
   - Gap analysis

2. **Security Control Review**
   - SCP effectiveness
   - Config rule updates
   - Security Hub standards review

3. **Disaster Recovery Testing**
   - Log restoration testing
   - Backup validation
   - Recovery procedures

## Incident Response

### Severity Levels

**Critical (P1)**
- Root account compromise
- Data breach
- Ransomware/malware
- Response time: Immediate

**High (P2)**
- Unauthorized access
- Service disruption
- Compliance violation
- Response time: 1 hour

**Medium (P3)**
- Policy violations
- Configuration drift
- Failed compliance checks
- Response time: 4 hours

**Low (P4)**
- Informational findings
- Best practice deviations
- Response time: 24 hours

### Response Workflow

1. **Detection**
   - Alert received via SNS
   - Finding in Security Hub/GuardDuty
   - CloudWatch alarm triggered

2. **Triage**
   - Assess severity
   - Determine scope
   - Assign incident commander

3. **Containment**
   - Isolate affected resources
   - Revoke compromised credentials
   - Apply emergency SCPs

4. **Investigation**
   - CloudTrail log analysis
   - VPC Flow Log review
   - GuardDuty finding details

5. **Remediation**
   - Remove threat
   - Patch vulnerabilities
   - Restore from backup if needed

6. **Recovery**
   - Restore normal operations
   - Verify security posture
   - Monitor for recurrence

7. **Post-Incident**
   - Root cause analysis
   - Lessons learned
   - Update runbooks
   - Improve detection

## Best Practices

### Security

1. **Enable MFA Everywhere**
   - Root account (hardware MFA)
   - IAM users
   - Privileged roles

2. **Principle of Least Privilege**
   - Minimal IAM permissions
   - Time-bound access
   - Regular access reviews

3. **Defense in Depth**
   - Multiple security layers
   - Redundant controls
   - Fail-secure design

4. **Assume Breach**
   - Continuous monitoring
   - Rapid detection
   - Automated response

### Logging

1. **Log Everything**
   - API calls (CloudTrail)
   - Network traffic (VPC Flow Logs)
   - Application logs
   - Security events

2. **Protect Logs**
   - Encryption at rest
   - Encryption in transit
   - Immutable storage
   - Access controls

3. **Retain Appropriately**
   - Compliance requirements
   - Investigation needs
   - Cost optimization

4. **Analyze Continuously**
   - Real-time monitoring
   - Automated alerting
   - Trend analysis
   - Anomaly detection

### Compliance

1. **Automate Compliance**
   - Config rules
   - Security Hub standards
   - Automated remediation

2. **Continuous Monitoring**
   - Real-time compliance status
   - Drift detection
   - Automated reporting

3. **Evidence Collection**
   - Automated screenshots
   - Log exports
   - Compliance reports

4. **Regular Audits**
   - Internal reviews
   - External audits
   - Penetration testing

## Troubleshooting

### Common Issues

**CloudTrail Not Logging**
- Check S3 bucket policy
- Verify KMS key permissions
- Ensure trail is enabled

**GuardDuty No Findings**
- Verify detector is enabled
- Check data sources
- Review finding filters

**Config Rules Failing**
- Check IAM role permissions
- Verify S3 bucket access
- Review rule parameters

**Alarms Not Triggering**
- Verify metric filter pattern
- Check alarm threshold
- Ensure SNS subscriptions confirmed

## Cost Optimization

### Logging Costs

**S3 Storage:**
- Standard: $0.023/GB/month
- Glacier: $0.004/GB/month
- Deep Archive: $0.00099/GB/month

**Lifecycle Policy Savings:**
- 90-day transition: ~80% savings
- 365-day deep archive: ~95% savings

**CloudWatch Logs:**
- Ingestion: $0.50/GB
- Storage: $0.03/GB/month
- Retention policy reduces costs

### Security Service Costs

**GuardDuty:**
- CloudTrail: $4.00/million events
- VPC Flow Logs: $1.00/GB
- DNS Logs: $0.40/million queries

**Security Hub:**
- Finding ingestion: $0.0010/finding
- Compliance checks: $0.001/check
- Standards: Included

**Config:**
- Configuration items: $0.003/item
- Rule evaluations: $0.001/evaluation
- Conformance packs: $2.00/pack/region

**Optimization Tips:**
1. Use Config rules selectively
2. Filter GuardDuty findings
3. Aggregate Security Hub findings
4. Optimize log retention
5. Use S3 Intelligent-Tiering

## References

- [AWS Security Best Practices](https://aws.amazon.com/security/best-practices/)
- [CIS AWS Foundations Benchmark](https://www.cisecurity.org/benchmark/amazon_web_services)
- [AWS Compliance Programs](https://aws.amazon.com/compliance/programs/)
- [AWS Security Hub User Guide](https://docs.aws.amazon.com/securityhub/)
- [Amazon GuardDuty User Guide](https://docs.aws.amazon.com/guardduty/)
- [AWS Config Developer Guide](https://docs.aws.amazon.com/config/)

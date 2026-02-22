# Service Control Policies (SCPs) - Comprehensive Guide

## Overview

This Control Tower deployment includes 35+ comprehensive Service Control Policies (SCPs) organized into categories for maximum security and compliance.

## SCP Categories

### 1. Core Security Policies (4 SCPs)
### 2. Logging and Monitoring Protection (2 SCPs)
### 3. Encryption Requirements (6 SCPs)
### 4. S3 Security (4 SCPs)
### 5. EC2 Security (4 SCPs)
### 6. Network Security (3 SCPs)
### 7. IAM Security (3 SCPs)
### 8. KMS Security (1 SCP)
### 9. Database Security (4 SCPs)
### 10. Additional Service Policies (4 SCPs)

---

## Detailed Policy Descriptions

### Core Security Policies

#### 1. deny_root_user
**Purpose**: Prevent use of root account credentials

**What it does**:
- Blocks all API calls made by the root user
- Exceptions: None
- Applies to: All accounts

**Why it's important**:
- Root user has unrestricted access
- Cannot be limited by IAM policies
- Compromise = complete account takeover
- CIS AWS Foundations Benchmark requirement

**Recommendation**: Always enabled

---

#### 2. require_mfa
**Purpose**: Enforce Multi-Factor Authentication

**What it does**:
- Denies all API calls without MFA
- Exceptions: MFA device management actions
- Applies to: IAM users (not roles)

**Allowed without MFA**:
- `iam:CreateVirtualMFADevice`
- `iam:EnableMFADevice`
- `iam:GetUser`
- `iam:ListMFADevices`
- `iam:ResyncMFADevice`
- `sts:GetSessionToken`

**Why it's important**:
- Prevents credential theft attacks
- Adds second factor of authentication
- SOC 2 and ISO 27001 requirement

**Recommendation**: Enabled for non-prod and prod OUs

---

#### 3. restrict_regions
**Purpose**: Limit operations to approved AWS regions

**What it does**:
- Blocks API calls outside allowed regions
- Exceptions: Global services (IAM, Route53, CloudFront, etc.)
- Configurable region list

**Default allowed regions**:
- ap-southeast-2 (Sydney)
- ap-southeast-1 (Singapore)
- us-east-1 (Global services)

**Why it's important**:
- Data residency compliance
- Cost control
- Simplified management
- Reduced attack surface

**Recommendation**: Always enabled

---

#### 4. deny_leave_org
**Purpose**: Prevent accounts from leaving the organization

**What it does**:
- Blocks `organizations:LeaveOrganization`
- No exceptions

**Why it's important**:
- Prevents rogue account separation
- Maintains centralized governance
- Protects consolidated billing

**Recommendation**: Always enabled

---

### Logging and Monitoring Protection

#### 5. protect_cloudtrail
**Purpose**: Prevent CloudTrail tampering

**What it does**:
- Blocks deletion of trails
- Blocks stopping logging
- Blocks trail modifications

**Protected actions**:
- `cloudtrail:DeleteTrail`
- `cloudtrail:StopLogging`
- `cloudtrail:UpdateTrail`

**Why it's important**:
- Maintains audit trail
- Compliance requirement
- Forensic evidence preservation
- CIS AWS Foundations requirement

**Recommendation**: Always enabled

---

#### 6. protect_security_services
**Purpose**: Prevent disabling security services

**What it does**:
- Protects AWS Config
- Protects GuardDuty
- Protects Security Hub
- Protects Access Analyzer

**Protected services**:
- AWS Config (rules, recorder, delivery)
- GuardDuty (detector, members)
- Security Hub (hub, members)
- IAM Access Analyzer

**Why it's important**:
- Maintains security posture
- Continuous compliance monitoring
- Threat detection
- Security Hub findings

**Recommendation**: Always enabled

---

### Encryption Requirements

#### 7. require_encryption
**Purpose**: Enforce encryption for S3 and EBS

**What it does**:
- Requires S3 server-side encryption (AES256 or KMS)
- Requires EBS volume encryption
- Blocks unencrypted resources

**Applies to**:
- S3 PutObject operations
- EC2 CreateVolume
- EC2 RunInstances (EBS volumes)

**Why it's important**:
- Data protection at rest
- Compliance requirement (PCI DSS, HIPAA)
- Prevents data exposure

**Recommendation**: Always enabled

---

#### 8. deny_unencrypted_rds
**Purpose**: Require RDS encryption

**What it does**:
- Blocks creation of unencrypted RDS instances
- Blocks creation of unencrypted RDS clusters
- Applies to all database engines

**Why it's important**:
- Database security
- Compliance requirement
- Protects sensitive data

**Recommendation**: Always enabled

---

#### 9. deny_unencrypted_snapshots
**Purpose**: Require EBS snapshot encryption

**What it does**:
- Blocks creation of unencrypted snapshots
- Applies to all EBS volumes

**Why it's important**:
- Backup security
- Prevents data leakage
- Compliance requirement

**Recommendation**: Enabled

---

#### 10. require_kms_encryption
**Purpose**: Enforce KMS encryption for EFS and DynamoDB

**What it does**:
- Requires EFS encryption
- Requires DynamoDB KMS encryption
- Blocks default encryption

**Why it's important**:
- Centralized key management
- Key rotation
- Access control via key policies

**Recommendation**: Enabled

---

#### 11. deny_unencrypted_secrets
**Purpose**: Require KMS encryption for Secrets Manager

**What it does**:
- Blocks secrets without KMS encryption
- Requires explicit KMS key

**Why it's important**:
- Credential protection
- Key rotation
- Audit trail

**Recommendation**: Enabled

---

#### 12. deny_unencrypted_elasticache
**Purpose**: Require ElastiCache encryption

**What it does**:
- Requires at-rest encryption
- Requires in-transit encryption
- Applies to Redis and Memcached

**Why it's important**:
- Cache data protection
- Compliance requirement
- Network security

**Recommendation**: Enabled

---

### S3 Security

#### 13. deny_public_s3
**Purpose**: Prevent public S3 bucket settings

**What it does**:
- Blocks disabling public access block settings
- Enforces all four block settings:
  - BlockPublicAcls
  - BlockPublicPolicy
  - IgnorePublicAcls
  - RestrictPublicBuckets

**Why it's important**:
- Prevents data breaches
- Most common cloud misconfiguration
- Compliance requirement

**Recommendation**: Always enabled

---

#### 14. deny_s3_public_access
**Purpose**: Prevent public ACLs on S3

**What it does**:
- Blocks public-read ACL
- Blocks public-read-write ACL
- Blocks authenticated-read ACL

**Why it's important**:
- Additional layer of protection
- Prevents accidental exposure
- Defense in depth

**Recommendation**: Enabled

---

#### 15. require_s3_ssl
**Purpose**: Enforce HTTPS for S3 access

**What it does**:
- Blocks all S3 operations over HTTP
- Requires TLS/SSL

**Why it's important**:
- Data in transit protection
- Prevents man-in-the-middle attacks
- Compliance requirement

**Recommendation**: Always enabled

---

#### 16. require_s3_versioning
**Purpose**: Enforce S3 versioning

**What it does**:
- Blocks bucket creation without versioning
- Note: Restrictive policy

**Why it's important**:
- Data protection
- Ransomware protection
- Accidental deletion recovery

**Recommendation**: Optional (can be restrictive)

---

### EC2 Security

#### 17. restrict_instance_types
**Purpose**: Limit EC2 instance types

**What it does**:
- Allows only specified instance families
- Configurable patterns (e.g., t3.*, m5.*)
- Blocks expensive instance types

**Default allowed (non-prod)**:
- t3.* (general purpose)
- t3a.* (AMD general purpose)
- t4g.* (ARM general purpose)
- m5.* (production)

**Why it's important**:
- Cost control
- Prevents oversized instances
- Development environment control

**Recommendation**: Enabled for non-prod OU

---

#### 18. require_imdsv2
**Purpose**: Enforce IMDSv2 for EC2 metadata

**What it does**:
- Requires session-oriented metadata service
- Blocks IMDSv1 (open metadata service)

**Why it's important**:
- Prevents SSRF attacks
- Credential theft protection
- AWS security best practice

**Recommendation**: Always enabled

---

#### 19. deny_public_ami
**Purpose**: Prevent public AMI sharing

**What it does**:
- Blocks making AMIs public
- Blocks making snapshots public

**Why it's important**:
- Intellectual property protection
- Prevents data leakage
- Security configuration exposure

**Recommendation**: Enabled

---

#### 20. restrict_ec2_termination
**Purpose**: Require termination protection

**What it does**:
- Requires DisableApiTermination=true
- Prevents accidental termination

**Why it's important**:
- Production instance protection
- Prevents accidental deletion
- Business continuity

**Recommendation**: Enabled for production OU

---

### Network Security

#### 21. deny_vpc_internet_gateway_unauthorized
**Purpose**: Control Internet Gateway creation

**What it does**:
- Blocks IGW creation
- Blocks IGW attachment
- Centralizes internet access

**Why it's important**:
- Network architecture control
- Prevents unauthorized internet access
- Centralized egress

**Recommendation**: Optional (can be restrictive)

---

#### 22. require_vpc_flow_logs
**Purpose**: Enforce VPC Flow Logs

**What it does**:
- Blocks VPC creation without flow logs
- Note: Very restrictive

**Why it's important**:
- Network visibility
- Security monitoring
- Compliance requirement

**Recommendation**: Optional (requires automation)

---

#### 23. deny_default_vpc
**Purpose**: Prevent default VPC usage

**What it does**:
- Blocks launching resources in default VPC
- Applies to EC2, RDS, ELB

**Why it's important**:
- Default VPCs are less secure
- Encourages proper network design
- Best practice enforcement

**Recommendation**: Enabled

---

### IAM Security

#### 24. deny_iam_user_creation
**Purpose**: Enforce AWS SSO usage

**What it does**:
- Blocks IAM user creation
- Blocks access key creation
- Forces SSO adoption

**Why it's important**:
- Centralized identity management
- Eliminates long-term credentials
- Improved security posture

**Recommendation**: Enabled (after SSO setup)

---

#### 25. require_iam_password_policy
**Purpose**: Enforce strong passwords

**What it does**:
- Requires minimum 14 characters
- Blocks weak password policies

**Why it's important**:
- Password security
- Compliance requirement
- Brute force protection

**Recommendation**: Enabled

---

#### 26. deny_iam_policy_changes
**Purpose**: Restrict policy modifications

**What it does**:
- Blocks policy version creation
- Blocks policy deletion
- Exception: Admin roles

**Why it's important**:
- Prevents privilege escalation
- Policy integrity
- Change control

**Recommendation**: Optional (can be restrictive)

---

### KMS Security

#### 27. deny_kms_key_deletion
**Purpose**: Prevent immediate key deletion

**What it does**:
- Blocks ScheduleKeyDeletion
- Blocks DeleteAlias

**Why it's important**:
- Prevents data loss
- Accidental deletion protection
- Compliance requirement

**Recommendation**: Always enabled

---

### Database Security

#### 28. deny_public_rds
**Purpose**: Prevent publicly accessible RDS

**What it does**:
- Blocks PubliclyAccessible=true
- Applies to instances and modifications

**Why it's important**:
- Database security
- Prevents unauthorized access
- Compliance requirement

**Recommendation**: Always enabled

---

#### 29. require_rds_backup
**Purpose**: Enforce RDS backups

**What it does**:
- Requires minimum 7-day retention
- Blocks instances without backups

**Why it's important**:
- Data protection
- Disaster recovery
- Compliance requirement

**Recommendation**: Always enabled

---

#### 30. require_rds_multi_az
**Purpose**: Enforce Multi-AZ for RDS

**What it does**:
- Requires MultiAz=true
- Applies to production databases

**Why it's important**:
- High availability
- Automatic failover
- Production requirement

**Recommendation**: Enabled for production OU

---

#### 31. deny_public_redshift
**Purpose**: Prevent public Redshift clusters

**What it does**:
- Blocks PubliclyAccessible=true
- Applies to clusters

**Why it's important**:
- Data warehouse security
- Prevents unauthorized access
- Compliance requirement

**Recommendation**: Enabled if using Redshift

---

### Additional Service Policies

#### 32. restrict_lambda_vpc
**Purpose**: Require Lambda in VPC

**What it does**:
- Blocks Lambda without VPC configuration
- Enforces network isolation

**Why it's important**:
- Network security
- Resource access control
- Compliance requirement

**Recommendation**: Optional (can be restrictive)

---

#### 33. require_elb_logging
**Purpose**: Enforce load balancer logging

**What it does**:
- Requires access logs enabled
- Applies to ALB, NLB, CLB

**Why it's important**:
- Traffic visibility
- Security monitoring
- Compliance requirement

**Recommendation**: Enabled

---

#### 34. restrict_resource_deletion
**Purpose**: Prevent critical resource deletion

**What it does**:
- Blocks deletion of VPCs, subnets, route tables
- Blocks deletion of RDS, S3, DynamoDB
- Exception: Admin roles

**Why it's important**:
- Prevents accidental deletion
- Production protection
- Change control

**Recommendation**: Optional (can be restrictive)

---

#### 35. require_tagging
**Purpose**: Enforce resource tagging

**What it does**:
- Requires "Environment" tag
- Applies to EC2, EBS, RDS, S3

**Why it's important**:
- Cost allocation
- Resource management
- Compliance tracking

**Recommendation**: Enabled

---

## SCP Assignment Strategy

### Root OU (All Accounts)
```hcl
root_scp_policies = [
  "deny_root_user",
  "deny_leave_org",
  "protect_cloudtrail",
  "protect_security_services",
  "restrict_regions",
  "require_encryption",
  "deny_unencrypted_rds",
  "deny_kms_key_deletion",
  "require_s3_ssl",
  "deny_public_s3",
  "deny_public_rds",
  "require_imdsv2"
]
```

### Development OU
```hcl
ou_scp_policies = {
  development = [
    "require_mfa",
    "restrict_instance_types",
    "deny_public_ami",
    "deny_default_vpc",
    "deny_iam_user_creation",
    "require_tagging"
  ]
}
```

### Testing OU
```hcl
ou_scp_policies = {
  testing = [
    "require_mfa",
    "restrict_instance_types",
    "deny_public_ami",
    "deny_default_vpc",
    "require_tagging"
  ]
}
```

### Staging OU
```hcl
ou_scp_policies = {
  staging = [
    "require_mfa",
    "deny_public_ami",
    "deny_default_vpc",
    "require_rds_backup",
    "require_tagging"
  ]
}
```

### Production OU
```hcl
ou_scp_policies = {
  production = [
    "require_mfa",
    "require_rds_multi_az",
    "require_rds_backup",
    "restrict_ec2_termination",
    "require_elb_logging",
    "require_tagging"
  ]
}
```

### Security OU
```hcl
ou_scp_policies = {
  security = [
    "require_mfa"
  ]
}
```

---

## Testing SCPs

### Before Enabling

1. **Review Policy**: Understand what it blocks
2. **Check Dependencies**: Ensure no breaking changes
3. **Test in Non-Prod**: Enable in development first
4. **Monitor Impact**: Watch for denied actions
5. **Adjust if Needed**: Refine policy or exceptions

### Testing Procedure

```bash
# 1. Enable in development OU
terraform apply -target=module.scp_attachments

# 2. Test affected operations
aws ec2 run-instances --instance-type t2.micro  # Should fail
aws ec2 run-instances --instance-type t3.micro  # Should succeed

# 3. Monitor CloudTrail for denied actions
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=RunInstances \
  --max-results 10

# 4. If successful, enable in production
```

---

## Troubleshooting

### Common Issues

**1. Legitimate Action Blocked**
- Review SCP policy
- Add exception if needed
- Consider alternative approach
- Document decision

**2. Policy Too Restrictive**
- Disable temporarily
- Refine policy
- Test thoroughly
- Re-enable

**3. Conflicting Policies**
- SCPs are cumulative (deny wins)
- Check all attached SCPs
- Review inheritance
- Simplify if possible

### Debugging Commands

```bash
# List attached SCPs
aws organizations list-policies-for-target \
  --target-id ou-xxxx \
  --filter SERVICE_CONTROL_POLICY

# View SCP content
aws organizations describe-policy \
  --policy-id p-xxxx

# Check denied actions in CloudTrail
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=ErrorCode,AttributeValue=AccessDenied
```

---

## Best Practices

1. **Start Conservative**: Enable core policies first
2. **Test Thoroughly**: Always test in non-prod
3. **Document Exceptions**: Track why policies are disabled
4. **Review Regularly**: Quarterly policy review
5. **Monitor Impact**: Watch CloudTrail for denials
6. **Communicate Changes**: Inform teams before enabling
7. **Maintain Flexibility**: Don't over-restrict
8. **Use Inheritance**: Apply common policies at root
9. **Layer Security**: Combine with IAM policies
10. **Audit Compliance**: Regular compliance checks

---

## Compliance Mapping

### CIS AWS Foundations Benchmark
- 1.4: Root account MFA → `deny_root_user`
- 1.5-1.11: IAM password policy → `require_iam_password_policy`
- 2.1: CloudTrail enabled → `protect_cloudtrail`
- 2.3: S3 bucket logging → `require_s3_ssl`
- 2.7: CloudTrail encryption → `require_encryption`

### SOC 2
- CC6.1: Logical access → `require_mfa`, `deny_root_user`
- CC6.6: Encryption → All encryption policies
- CC7.2: Monitoring → `protect_security_services`

### PCI DSS
- 2.1: Default passwords → `require_iam_password_policy`
- 3.4: Encryption → All encryption policies
- 8.2: MFA → `require_mfa`
- 10.1: Audit trails → `protect_cloudtrail`

---

## References

- [AWS SCP Documentation](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps.html)
- [SCP Examples](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps_examples.html)
- [CIS AWS Foundations Benchmark](https://www.cisecurity.org/benchmark/amazon_web_services)
- [AWS Security Best Practices](https://aws.amazon.com/security/best-practices/)

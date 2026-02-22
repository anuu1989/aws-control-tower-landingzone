# Zero Trust Architecture Module

Implements comprehensive Zero Trust security architecture for AWS Control Tower Landing Zone.

## Zero Trust Principles

1. **Never Trust, Always Verify** - Continuous authentication and authorization
2. **Assume Breach** - Design with the assumption that threats exist inside and outside
3. **Verify Explicitly** - Always authenticate and authorize based on all available data points
4. **Use Least Privilege Access** - Limit user access with Just-In-Time and Just-Enough-Access (JIT/JEA)
5. **Segment Access** - Use micro-segmentation and encryption to prevent lateral movement

## Features

### Identity & Access Management
- **IAM Access Analyzer** - Continuous monitoring of resource access
- **MFA Enforcement** - Mandatory multi-factor authentication
- **Session Manager** - Secure, audited access without SSH/RDP
- **AWS Verified Access** - Zero Trust network access

### Network Security
- **Private Subnets Only** - No direct internet access
- **VPC Endpoints** - Private connectivity to AWS services
- **VPC Flow Logs** - Complete network traffic logging
- **Network ACLs** - Defense in depth
- **Default Deny Security Groups** - Explicit allow rules only

### Application Security
- **AWS WAF** - Application layer protection with rate limiting
- **PrivateLink** - Service-to-service communication without internet
- **Geo-blocking** - Block traffic from specific countries
- **Managed Rule Sets** - AWS-managed security rules

### Data Protection
- **Encryption at Rest** - KMS encryption for all data
- **Encryption in Transit** - TLS for all communications
- **Secrets Manager** - Secure credential storage with rotation
- **S3 Encryption** - Mandatory encryption for all buckets

### Monitoring & Detection
- **Real-time Alerts** - Unauthorized access attempts
- **CloudWatch Alarms** - Anomaly detection
- **EventBridge Rules** - Security event monitoring
- **Audit Logging** - Complete audit trail

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Zero Trust VPC                            │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              Private Subnets (Multi-AZ)              │  │
│  │                                                       │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐ │  │
│  │  │   Workload  │  │   Workload  │  │   Workload  │ │  │
│  │  │     AZ-A    │  │     AZ-B    │  │     AZ-C    │ │  │
│  │  └─────────────┘  └─────────────┘  └─────────────┘ │  │
│  │         │                │                │          │  │
│  └─────────┼────────────────┼────────────────┼──────────┘  │
│            │                │                │              │
│  ┌─────────▼────────────────▼────────────────▼──────────┐  │
│  │              VPC Endpoints (Interface)               │  │
│  │  EC2 │ SSM │ KMS │ Secrets │ ECR │ ECS │ Logs │ STS │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │         VPC Endpoints (Gateway)                       │  │
│  │              S3 │ DynamoDB                            │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
└─────────────────────────────────────────────────────────────┘
                           │
                           │ (Monitored & Encrypted)
                           │
              ┌────────────▼────────────┐
              │   AWS Services          │
              │  - IAM Identity Center  │
              │  - GuardDuty            │
              │  - Security Hub         │
              │  - CloudTrail           │
              │  - Config               │
              └─────────────────────────┘
```

## Usage

```hcl
module "zero_trust" {
  source = "./modules/zero-trust"

  name_prefix        = "production"
  region             = "ap-southeast-2"
  vpc_cidr           = "10.100.0.0/16"
  availability_zones = ["ap-southeast-2a", "ap-southeast-2b", "ap-southeast-2c"]
  
  kms_key_id            = module.security.kms_key_id
  sns_topic_arn         = aws_sns_topic.security.arn
  session_logs_bucket   = module.logging.log_bucket_name
  
  # Zero Trust features
  enable_verified_access = true
  enable_privatelink     = true
  enable_waf             = true
  
  # Security thresholds
  unauthorized_calls_threshold = 5
  waf_rate_limit              = 2000
  blocked_countries           = ["KP", "IR", "SY"]
  
  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
    Security    = "zero-trust"
  }
}
```

## Components

### 1. Network Isolation
- Private subnets with no internet gateway
- VPC endpoints for AWS service access
- Network ACLs for subnet-level filtering
- VPC Flow Logs for traffic analysis

### 2. Identity Verification
- IAM Access Analyzer for continuous monitoring
- MFA enforcement policy
- AWS Verified Access for application access
- Session Manager for secure instance access

### 3. Application Protection
- AWS WAF with rate limiting
- Geo-blocking capabilities
- AWS Managed Rules integration
- Custom security rules

### 4. Monitoring & Alerting
- CloudWatch alarms for security events
- EventBridge rules for real-time detection
- SNS notifications for security team
- Comprehensive audit logging

## Security Controls

### Network Layer
- ✅ No direct internet access
- ✅ Private connectivity via VPC endpoints
- ✅ Network segmentation with NACLs
- ✅ Default deny security groups
- ✅ VPC Flow Logs enabled

### Identity Layer
- ✅ MFA enforcement
- ✅ Least privilege access
- ✅ Session logging and auditing
- ✅ Access Analyzer monitoring
- ✅ No long-term credentials

### Application Layer
- ✅ WAF protection
- ✅ Rate limiting
- ✅ Geo-blocking
- ✅ DDoS protection
- ✅ Managed security rules

### Data Layer
- ✅ Encryption at rest (KMS)
- ✅ Encryption in transit (TLS)
- ✅ Secrets rotation
- ✅ Secure credential storage
- ✅ Data classification

## Monitoring

### Real-time Alerts
- Unauthorized API calls
- Console login without MFA
- Security group changes
- IAM policy modifications
- Network anomalies

### Metrics
- VPC Flow Logs analysis
- WAF blocked requests
- Access Analyzer findings
- Session Manager activity
- API call patterns

## Compliance

Supports compliance with:
- **NIST 800-207** - Zero Trust Architecture
- **NIST 800-53** - Security and Privacy Controls
- **PCI DSS** - Payment Card Industry Data Security Standard
- **HIPAA** - Health Insurance Portability and Accountability Act
- **SOC 2** - Service Organization Control 2
- **ISO 27001** - Information Security Management

## Best Practices

1. **Continuous Verification**
   - Verify every access request
   - Use MFA for all users
   - Monitor access patterns

2. **Least Privilege**
   - Grant minimum required permissions
   - Use temporary credentials
   - Regular access reviews

3. **Micro-segmentation**
   - Isolate workloads
   - Use security groups effectively
   - Implement network boundaries

4. **Encryption Everywhere**
   - Encrypt data at rest
   - Encrypt data in transit
   - Use AWS KMS for key management

5. **Assume Breach**
   - Monitor for anomalies
   - Have incident response plan
   - Regular security testing

## Outputs

- `vpc_id` - Zero Trust VPC ID
- `private_subnet_ids` - Private subnet IDs
- `access_analyzer_arn` - IAM Access Analyzer ARN
- `mfa_policy_arn` - MFA enforcement policy ARN
- `verified_access_instance_id` - Verified Access instance ID
- `vpc_endpoints` - VPC endpoint IDs
- `waf_web_acl_arn` - WAF Web ACL ARN
- `security_monitoring` - Security monitoring resources

## Requirements

- Terraform >= 1.5.0
- AWS Provider >= 5.0
- KMS key for encryption
- SNS topic for notifications
- S3 bucket for session logs

## Notes

- All resources are created in private subnets
- No direct internet access is allowed
- All AWS service access is via VPC endpoints
- MFA is enforced for all users
- All actions are logged and monitored
- Encryption is mandatory for all data

## References

- [NIST Zero Trust Architecture](https://www.nist.gov/publications/zero-trust-architecture)
- [AWS Zero Trust on AWS](https://aws.amazon.com/security/zero-trust/)
- [AWS Verified Access](https://aws.amazon.com/verified-access/)
- [AWS PrivateLink](https://aws.amazon.com/privatelink/)

# AWS Control Tower Landing Zone - Complete Implementation Guide

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Features](#features)
4. [Prerequisites](#prerequisites)
5. [Quick Start](#quick-start)
6. [Detailed Implementation](#detailed-implementation)
7. [Testing Framework](#testing-framework)
8. [Zero Trust Architecture](#zero-trust-architecture)
9. [Backend Configuration](#backend-configuration)
10. [Operational Guide](#operational-guide)
11. [Troubleshooting](#troubleshooting)
12. [Cost Optimization](#cost-optimization)

---

## Overview

This is an enterprise-grade AWS Control Tower Landing Zone implementation with comprehensive security, governance, and Zero Trust architecture. The solution is fully modular, tested, and production-ready.

### Key Highlights

- ✅ **Terraform 1.6+** with native S3 state locking (no DynamoDB)
- ✅ **35 Service Control Policies** for comprehensive governance
- ✅ **Zero Trust Architecture** following NIST 800-207
- ✅ **Modular Design** with 9 reusable modules
- ✅ **Comprehensive Testing** with Terratest and OPA policies
- ✅ **Enterprise Security** with KMS, GuardDuty, Security Hub, Config
- ✅ **Centralized Networking** with Transit Gateway and Network Firewall
- ✅ **Complete Monitoring** with CloudWatch, CloudTrail, and EventBridge

### Project Statistics

- **Modules**: 9 (control-tower, OUs, SCPs, security, logging, networking, zero-trust, backend)
- **Service Control Policies**: 35 policies across 10 categories
- **OPA Policies**: 50+ rules in 11 modular files
- **Unit Tests**: 15 Terratest suites in 5 files
- **Lines of Code**: 10,000+ lines of Terraform
- **Documentation**: 15+ comprehensive guides

---

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                    AWS Control Tower Landing Zone                    │
│                                                                       │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │                    Management Account                          │  │
│  │  • Control Tower                                               │  │
│  │  • Organizations                                               │  │
│  │  • SCPs (35 policies)                                         │  │
│  │  • CloudTrail (Organization Trail)                            │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                       │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │                    Core Accounts                               │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐          │  │
│  │  │   Log       │  │   Audit     │  │  Security   │          │  │
│  │  │  Archive    │  │   Account   │  │   Account   │          │  │
│  │  └─────────────┘  └─────────────┘  └─────────────┘          │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                       │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │              Organizational Units (Extensible)                 │  │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐     │  │
│  │  │ Security │  │   Infra  │  │   Dev    │  │   Prod   │     │  │
│  │  │    OU    │  │    OU    │  │    OU    │  │    OU    │     │  │
│  │  └──────────┘  └──────────┘  └──────────┘  └──────────┘     │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                       │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │                    Security Services                           │  │
│  │  • GuardDuty  • Security Hub  • AWS Config  • Macie          │  │
│  │  • Access Analyzer  • KMS  • Secrets Manager                  │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                       │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │                    Networking (Optional)                       │  │
│  │  • Transit Gateway  • Network Firewall  • DNS Firewall        │  │
│  │  • VPC Flow Logs  • NAT Gateways  • VPC Endpoints            │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                       │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │                    Zero Trust (Optional)                       │  │
│  │  • Private Subnets  • VPC Endpoints  • Verified Access        │  │
│  │  • MFA Enforcement  • Session Manager  • WAF                  │  │
│  └───────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

### Module Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Root Module                               │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  control-tower        │  Creates landing zone        │  │
│  └──────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  organizational-units │  Manages OUs (extensible)    │  │
│  └──────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  scp-policies         │  35 governance policies      │  │
│  └──────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  scp-attachments      │  Policy-to-OU mapping        │  │
│  └──────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  security             │  KMS, GuardDuty, Hub, Config │  │
│  └──────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  logging              │  CloudTrail, S3, CloudWatch  │  │
│  └──────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  networking           │  TGW, Firewall, DNS Firewall │  │
│  └──────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  zero-trust           │  Zero Trust architecture     │  │
│  └──────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  terraform-backend    │  S3 state with native lock   │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## Features

### 1. Control Tower Landing Zone

- **Multi-Account Structure**: Management, Log Archive, Audit accounts
- **Home Region**: Sydney (ap-southeast-2)
- **Governed Regions**: Configurable list of allowed regions
- **Account Factory**: Automated account provisioning
- **Guardrails**: Preventive and detective controls

### 2. Organizational Units (Extensible)

- **Fully Dynamic**: Add unlimited OUs without code changes
- **Default OUs**: Security, Infrastructure, Dev, Test, Staging, Prod
- **Custom Tags**: Per-OU tagging for cost allocation
- **SCP Assignment**: Flexible policy-to-OU mapping

### 3. Service Control Policies (35 Policies)

**Core Security** (4):
- deny_root_user
- require_mfa
- restrict_regions
- deny_leave_org

**Logging & Monitoring** (2):
- protect_cloudtrail
- protect_security_services

**Encryption** (6):
- require_encryption
- deny_unencrypted_rds
- deny_unencrypted_snapshots
- require_kms_encryption
- deny_unencrypted_secrets
- deny_unencrypted_elasticache

**S3 Security** (4):
- deny_public_s3
- deny_s3_public_access
- require_s3_ssl
- require_s3_versioning

**EC2 Security** (4):
- restrict_instance_types
- require_imdsv2
- deny_public_ami
- restrict_ec2_termination

**Network Security** (3):
- deny_vpc_internet_gateway_unauthorized
- require_vpc_flow_logs
- deny_default_vpc

**IAM Security** (3):
- deny_iam_user_creation
- require_iam_password_policy
- deny_iam_policy_changes

**Database Security** (5):
- deny_public_rds
- require_rds_backup
- require_rds_multi_az
- deny_public_redshift
- deny_kms_key_deletion

**Additional Services** (4):
- restrict_lambda_vpc
- require_elb_logging
- restrict_resource_deletion
- require_tagging

### 4. Security Module

- **KMS**: Customer-managed keys with automatic rotation
- **GuardDuty**: Threat detection across all accounts
- **Security Hub**: Centralized security findings
- **AWS Config**: 10 compliance rules
- **Access Analyzer**: Continuous access monitoring
- **Macie**: Sensitive data discovery (optional)

### 5. Logging Module

- **CloudTrail**: Organization trail with insights
- **S3 Log Archive**: 7-year retention with lifecycle
- **CloudWatch Logs**: Centralized logging
- **Metric Filters**: 6 security metric filters
- **Alarms**: Real-time security alerts
- **SNS Notifications**: Two-tier alerting

### 6. Networking Module (Optional)

- **Transit Gateway**: 4 route tables for segmentation
- **Network Firewall**: Stateful/stateless rules
- **DNS Firewall**: Malicious domain blocking
- **NAT Gateways**: 3 AZs for high availability
- **VPC Flow Logs**: Complete traffic logging
- **Network Access Analyzer**: Path analysis

### 7. Zero Trust Module (Optional)

**Identity & Access**:
- IAM Access Analyzer
- MFA enforcement policy
- AWS Verified Access
- Session Manager (no SSH/RDP)

**Network Segmentation**:
- Private subnets only
- VPC endpoints (15+ services)
- VPC Flow Logs
- Network ACLs
- Default deny security groups

**Application Protection**:
- AWS WAF with rate limiting
- Geo-blocking
- AWS Managed Rules
- PrivateLink

**Data Protection**:
- KMS encryption everywhere
- TLS for all communications
- Secrets Manager with rotation

**Monitoring**:
- CloudWatch alarms
- EventBridge rules
- Real-time alerts

### 8. Testing Framework

**Terratest Unit Tests** (15 suites):
- Control Tower deployment
- Organizational units
- SCP policies
- Security module
- Logging module
- Networking module
- Variable validation
- Output verification

**OPA Policy Tests** (50+ rules):
- Encryption policies
- S3 security
- EC2 security
- RDS security
- Network security
- IAM security
- Monitoring policies
- Zero Trust policies

**Security Scanning**:
- TFSec integration
- Checkov integration
- TFLint configuration

### 9. Backend Infrastructure

- **Terraform 1.6+**: Native S3 state locking
- **No DynamoDB**: Simpler, cheaper architecture
- **KMS Encryption**: Automatic key rotation
- **Versioning**: 90-day retention
- **Lifecycle Policies**: Cost optimization
- **Monitoring**: CloudWatch alarms

---

## Prerequisites

### Required Tools

| Tool | Version | Purpose |
|------|---------|---------|
| Terraform | >= 1.6.0 | Infrastructure as Code |
| AWS CLI | >= 2.0 | AWS API access |
| Go | >= 1.21 | Terratest unit tests |
| OPA | >= 0.60.0 | Policy validation |

### Optional Tools

| Tool | Purpose |
|------|---------|
| TFLint | Terraform linting |
| TFSec | Security scanning |
| Checkov | Compliance scanning |
| jq | JSON processing |

### AWS Requirements

- **Account**: AWS Organizations enabled in management account
- **Permissions**: Administrator access
- **Email Addresses**: Minimum 2 (Log Archive, Audit accounts)
- **Service Quotas**: Verify limits for your organization size

### Installation

```bash
# Terraform
brew install terraform

# AWS CLI
brew install awscli

# Go (for Terratest)
brew install go

# OPA (for policy tests)
brew install opa

# Optional tools
brew install tflint tfsec jq
pip install checkov
```

---

## Quick Start

### Step 1: Deploy Backend (First Time Only)

```bash
# Navigate to backend directory
cd backend

# Configure backend
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars

# Required changes:
# - Set unique state_bucket_name
# - Add your AWS account ARN to allowed_account_ids

# Deploy backend infrastructure
terraform init
terraform apply

# Save backend configuration
terraform output -raw backend_config_hcl > ../backend.hcl

# Return to root
cd ..
```

### Step 2: Initialize Main Terraform

```bash
# Initialize with backend
terraform init -backend-config=backend.hcl

# Verify backend configuration
terraform state list
```

### Step 3: Configure Control Tower

```bash
# Copy production configuration
cp terraform.tfvars.production terraform.tfvars

# Edit configuration
vim terraform.tfvars

# Required changes:
# - Set environment and project_name
# - Configure organizational_units
# - Set notification emails
# - Review and adjust SCPs
```

### Step 4: Validate Configuration

```bash
# Run pre-deployment checks
make pre-deploy

# Or manually:
./scripts/pre-deployment-check.sh
```

### Step 5: Deploy Control Tower

```bash
# Generate plan
terraform plan -out=tfplan

# Review plan carefully
terraform show tfplan

# Apply (60-90 minutes)
terraform apply tfplan

# Run post-deployment checklist
./scripts/post-deployment.sh
```

---

## Detailed Implementation

### Backend Configuration

See [BACKEND.md](BACKEND.md) for complete backend setup guide.

**Key Points**:
- Uses Terraform 1.6+ native S3 state locking
- No DynamoDB table required
- 50% cost reduction vs traditional backend
- Modular and reusable design

### Control Tower Deployment

See [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) for step-by-step deployment.

**Timeline**:
- Backend deployment: 5-10 minutes
- Control Tower setup: 60-90 minutes
- Post-deployment configuration: 30-60 minutes

### Security Configuration

See [SECURITY.md](SECURITY.md) for security features and controls.

**Security Layers**:
1. **Preventive**: SCPs, security groups, NACLs
2. **Detective**: GuardDuty, Security Hub, Config
3. **Responsive**: CloudWatch alarms, EventBridge rules
4. **Forensic**: CloudTrail, VPC Flow Logs

### Networking Setup

See [NETWORKING.md](NETWORKING.md) for network architecture.

**Components**:
- Transit Gateway for connectivity
- Network Firewall for inspection
- DNS Firewall for threat prevention
- VPC endpoints for private access

### Zero Trust Implementation

See [ZERO_TRUST.md](ZERO_TRUST.md) for Zero Trust architecture.

**Principles**:
1. Never trust, always verify
2. Assume breach
3. Verify explicitly
4. Least privilege access
5. Segment access

---

## Testing Framework

See [TESTING.md](TESTING.md) for complete testing guide.

### Running Tests

```bash
# Run all tests
make test-all

# Run specific test suites
make test-unit              # Terratest
make test-opa               # OPA policies
make lint                   # TFLint
make security-scan          # TFSec

# Individual scripts
./scripts/run-terraform-tests.sh
./scripts/run-opa-tests.sh
./scripts/validate-all.sh
```

### Test Coverage

- ✅ Infrastructure deployment
- ✅ Module functionality
- ✅ Security policies
- ✅ Compliance rules
- ✅ Variable validation
- ✅ Output verification

---

## Zero Trust Architecture

See [ZERO_TRUST.md](ZERO_TRUST.md) for detailed implementation.

### Deployment

```hcl
module "zero_trust" {
  source = "./modules/zero-trust"

  name_prefix        = var.project_name
  region             = var.home_region
  vpc_cidr           = "10.100.0.0/16"
  availability_zones = ["ap-southeast-2a", "ap-southeast-2b", "ap-southeast-2c"]
  
  kms_key_id          = module.security.kms_key_id
  sns_topic_arn       = aws_sns_topic.security.arn
  session_logs_bucket = module.logging.log_bucket_name
  
  enable_verified_access = true
  enable_privatelink     = true
  enable_waf             = true
  
  tags = local.common_tags
}
```

### Features

- Private subnets with VPC endpoints
- MFA enforcement
- Session Manager for secure access
- AWS WAF for application protection
- Continuous monitoring

---

## Backend Configuration

See [BACKEND.md](BACKEND.md) for complete backend guide.

### Module Usage

```hcl
module "terraform_backend" {
  source = "./modules/terraform-backend"

  name_prefix       = "control-tower"
  state_bucket_name = "my-org-control-tower-terraform-state"
  
  allowed_principals = ["arn:aws:iam::123456789012:root"]
  
  state_retention_days = 90
  logs_retention_days  = 365
  
  enable_logging    = true
  enable_monitoring = true
  create_iam_policy = true
  
  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

### Cost Optimization

- No DynamoDB charges
- Lifecycle policies for storage
- Pay-per-request billing
- Estimated cost: $5-10/month

---

## Operational Guide

### Daily Operations

1. **Monitor Security Dashboard**
   - Review GuardDuty findings
   - Check Security Hub compliance
   - Review CloudWatch alarms

2. **Access Reviews**
   - Review Access Analyzer findings
   - Validate temporary access
   - Audit session manager activity

3. **Incident Response**
   - Investigate security alerts
   - Review CloudTrail logs
   - Document findings

### Weekly Operations

1. **Policy Reviews**
   - Review IAM policies
   - Validate security group rules
   - Check VPC endpoint usage

2. **Compliance Checks**
   - Run Config compliance reports
   - Review OPA policy violations
   - Update remediation plans

### Monthly Operations

1. **Access Certification**
   - Review user access
   - Validate role assignments
   - Remove unused permissions

2. **Security Assessments**
   - Run vulnerability scans
   - Review architecture changes
   - Update threat models

### Maintenance Commands

```bash
# Check for drift
make check-drift

# Refresh state
make refresh

# Backup state
make backup-state

# View outputs
make output

# Run validation
make validate
```

---

## Troubleshooting

### Common Issues

#### Issue: State Lock Timeout

**Symptom**: Terraform hangs waiting for state lock

**Solution**:
```bash
# Check for lock file (Terraform 1.6+)
aws s3 ls s3://your-bucket/.terraform.lock.info

# Remove stale lock (use with caution!)
aws s3 rm s3://your-bucket/.terraform.lock.info
```

#### Issue: Access Denied

**Symptom**: Permission errors accessing resources

**Solution**:
1. Verify IAM permissions
2. Check bucket/resource policies
3. Verify KMS key policy
4. Ensure account ID in allowed list

#### Issue: Control Tower Already Exists

**Symptom**: Error that Control Tower is already set up

**Solution**:
1. Review existing setup
2. Consider using `terraform import`
3. Or manage existing setup separately

#### Issue: Service Quota Exceeded

**Symptom**: Quota limit errors

**Solution**:
1. Request quota increase via AWS Support
2. Review current usage
3. Clean up unused resources

### Debug Commands

```bash
# Enable debug logging
export TF_LOG=DEBUG
terraform plan

# Validate configuration
terraform validate

# Check formatting
terraform fmt -check -recursive

# Run diagnostics
make validate
```

---

## Cost Optimization

### Monthly Cost Estimate

| Component | Cost | Notes |
|-----------|------|-------|
| Control Tower | Free | AWS service |
| S3 (State) | $1-2 | Based on state size |
| KMS | $1 | Per key |
| GuardDuty | $5-20 | Based on usage |
| Security Hub | $1-5 | Per account |
| Config | $2-10 | Per rule/account |
| CloudTrail | $2-5 | Data events |
| VPC Flow Logs | $5-15 | Based on traffic |
| Network Firewall | $50-100 | If enabled |
| **Total** | **$70-160/month** | Varies by usage |

### Cost Optimization Tips

1. **Use Lifecycle Policies**
   - Transition logs to cheaper storage
   - Delete old versions automatically

2. **Right-Size Resources**
   - Review GuardDuty findings frequency
   - Adjust Config rule evaluation

3. **Enable Cost Allocation Tags**
   - Tag all resources
   - Track costs by OU/project

4. **Use Reserved Capacity**
   - For predictable workloads
   - Significant savings

5. **Monitor Usage**
   - Set up billing alarms
   - Review Cost Explorer regularly

---

## Compliance

### Supported Frameworks

- ✅ **NIST 800-207**: Zero Trust Architecture
- ✅ **NIST 800-53**: Security and Privacy Controls
- ✅ **PCI DSS**: Payment Card Industry
- ✅ **HIPAA**: Health Insurance Portability
- ✅ **SOC 2**: Service Organization Control
- ✅ **ISO 27001**: Information Security Management
- ✅ **CIS AWS Foundations**: Benchmark compliance

### Compliance Mapping

See [SCP_POLICIES.md](SCP_POLICIES.md) for detailed policy mappings.

---

## Support

### Documentation

- [Architecture](ARCHITECTURE.md) - System architecture
- [Deployment Guide](DEPLOYMENT_GUIDE.md) - Step-by-step deployment
- [Security](SECURITY.md) - Security features
- [Networking](NETWORKING.md) - Network architecture
- [SCP Policies](SCP_POLICIES.md) - Policy documentation
- [Testing](TESTING.md) - Testing framework
- [Backend](BACKEND.md) - Backend configuration
- [Zero Trust](ZERO_TRUST.md) - Zero Trust implementation

### Getting Help

1. Review documentation
2. Check troubleshooting section
3. Review GitHub issues
4. Contact AWS Support for Control Tower issues

---

## Summary

This implementation provides:

- ✅ Enterprise-grade AWS Control Tower Landing Zone
- ✅ 35 Service Control Policies for governance
- ✅ Zero Trust architecture following NIST 800-207
- ✅ Comprehensive security with multiple layers
- ✅ Centralized networking with inspection
- ✅ Complete testing framework
- ✅ Modular, reusable design
- ✅ Production-ready with monitoring
- ✅ Cost-optimized with lifecycle policies
- ✅ Compliance-ready for multiple frameworks

**Total Implementation**: 10,000+ lines of code, 15+ documentation guides, production-tested and validated.

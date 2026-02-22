# Account Vending - Automated Account Creation and Bootstrapping

## Overview

The Account Vending module provides automated AWS account creation and bootstrapping with baseline configurations. This enables teams to quickly provision new AWS accounts with consistent security, networking, and operational baselines.

## Table of Contents
1. [Features](#features)
2. [Architecture](#architecture)
3. [Quick Start](#quick-start)
4. [Configuration](#configuration)
5. [Bootstrapping Details](#bootstrapping-details)
6. [Adding New Accounts](#adding-new-accounts)
7. [Cost Considerations](#cost-considerations)
8. [Security](#security)
9. [Troubleshooting](#troubleshooting)
10. [Best Practices](#best-practices)

---

## Features

### Account Management
- ✅ Automated AWS account creation
- ✅ Placement in specified Organizational Units
- ✅ Unique email address per account
- ✅ Cross-account access role configuration
- ✅ Account tagging and metadata

### Network Bootstrapping
- ✅ VPC with public and private subnets
- ✅ Multi-AZ deployment (2-3 AZs)
- ✅ NAT Gateways for private subnet internet access
- ✅ Internet Gateway for public subnets
- ✅ VPC Flow Logs for network monitoring
- ✅ Route tables and associations
- ✅ Optional VPN Gateway

### Security Bootstrapping
- ✅ Baseline security groups
- ✅ IAM roles (Admin, ReadOnly, Developer, Terraform)
- ✅ GuardDuty threat detection
- ✅ Security Hub compliance monitoring
- ✅ AWS Config resource tracking
- ✅ Access Analyzer for IAM policies
- ✅ KMS encryption

### Operational Bootstrapping
- ✅ CloudWatch Log Groups
- ✅ VPC Flow Logs
- ✅ S3 buckets (logs, backups, data)
- ✅ SSM Parameter Store configuration
- ✅ SNS notifications integration

### Extensibility
- ✅ Fully extensible account list
- ✅ Per-account customization
- ✅ Optional bootstrapping
- ✅ Idempotent operations

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Management Account                        │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │         Account Vending Module (Terraform)             │ │
│  │                                                        │ │
│  │  1. Create AWS Account                                │ │
│  │  2. Wait for account provisioning (60s)               │ │
│  │  3. Assume OrganizationAccountAccessRole              │ │
│  │  4. Bootstrap account:                                │ │
│  │     ├── Create VPC                                    │ │
│  │     ├── Create Security Groups                        │ │
│  │     ├── Create IAM Roles                              │ │
│  │     ├── Enable Security Services                      │ │
│  │     ├── Configure Logging                             │ │
│  │     └── Create S3 Buckets                             │ │
│  │  5. Store configuration in SSM                        │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
└──────────────────────────┬───────────────────────────────────┘
                           │
                           │ Creates & Bootstraps
                           │
        ┌──────────────────┴──────────────────┐
        │                                     │
┌───────▼────────┐                   ┌────────▼───────┐
│  NonProd OU    │                   │   Prod OU      │
│                │                   │                │
│  ┌──────────┐  │                   │  ┌──────────┐  │
│  │   Dev    │  │                   │  │   Prod   │  │
│  │ Account  │  │                   │  │ Account  │  │
│  │          │  │                   │  │          │  │
│  │ VPC      │  │                   │  │ VPC      │  │
│  │ SGs      │  │                   │  │ SGs      │  │
│  │ IAM      │  │                   │  │ IAM      │  │
│  │ Security │  │                   │  │ Security │  │
│  │ Logging  │  │                   │  │ Logging  │  │
│  │ S3       │  │                   │  │ S3       │  │
│  └──────────┘  │                   │  └──────────┘  │
│                │                   │                │
│  ┌──────────┐  │                   └────────────────┘
│  │   Test   │  │
│  │ Account  │  │
│  │          │  │
│  │ VPC      │  │
│  │ SGs      │  │
│  │ IAM      │  │
│  │ Security │  │
│  │ Logging  │  │
│  │ S3       │  │
│  └──────────┘  │
│                │
└────────────────┘
```

---

## Quick Start

### 1. Add Account Vending Module to Main Configuration

```terraform
# main.tf

module "account_vending" {
  source = "./modules/account-vending"

  management_account_id  = data.aws_caller_identity.current.account_id
  home_region            = var.home_region
  enable_bootstrapping   = true
  
  central_log_bucket     = module.logging.log_bucket_id
  kms_key_id             = module.security.kms_key_id
  security_sns_topic_arn = aws_sns_topic.security_notifications.arn

  accounts = {
    dev = {
      name               = "Development"
      email              = "aws-dev@example.com"
      ou_id              = module.organizational_units.ou_ids["nonprod"]
      environment        = "dev"
      role_name          = "OrganizationAccountAccessRole"
      vpc_cidr           = "10.1.0.0/16"
      availability_zones = ["ap-southeast-2a", "ap-southeast-2b"]
      enable_nat_gateway = true
      single_nat_gateway = true
      enable_vpn_gateway = false
      allowed_ssh_cidrs  = ["10.0.0.0/8"]
      allowed_https_cidrs = ["0.0.0.0/0"]
      enable_admin_role     = true
      enable_readonly_role  = true
      enable_developer_role = true
      enable_guardduty       = true
      enable_securityhub     = true
      enable_config          = true
      enable_access_analyzer = true
      create_data_bucket     = true
      tags = { CostCenter = "Engineering" }
    }
  }

  tags = {
    ManagedBy = "Terraform"
  }
}
```

### 2. Deploy

```bash
# Initialize Terraform
terraform init

# Review plan
terraform plan

# Apply (account creation takes 5-10 minutes per account)
terraform apply
```

### 3. Access New Account

```bash
# Assume role in new account
aws sts assume-role \
  --role-arn arn:aws:iam::<ACCOUNT-ID>:role/OrganizationAccountAccessRole \
  --role-session-name terraform

# Export credentials
export AWS_ACCESS_KEY_ID=<AccessKeyId>
export AWS_SECRET_ACCESS_KEY=<SecretAccessKey>
export AWS_SESSION_TOKEN=<SessionToken>

# Verify access
aws sts get-caller-identity
```

---

## Configuration

### Account Object Structure

```terraform
account_key = {
  # Required Fields
  name        = string  # Account name (e.g., "Development")
  email       = string  # Unique email (e.g., "aws-dev@example.com")
  ou_id       = string  # OU ID where account will be created
  environment = string  # Environment tag (e.g., "dev", "prod")
  role_name   = string  # Cross-account access role name

  # VPC Configuration
  vpc_cidr           = string       # VPC CIDR block (e.g., "10.1.0.0/16")
  availability_zones = list(string) # AZs (e.g., ["ap-southeast-2a", "ap-southeast-2b"])
  enable_nat_gateway = bool         # Enable NAT Gateway (true/false)
  single_nat_gateway = bool         # Use single NAT (true for cost savings)
  enable_vpn_gateway = bool         # Enable VPN Gateway (true/false)

  # Security Configuration
  allowed_ssh_cidrs   = list(string) # CIDRs for SSH access
  allowed_https_cidrs = list(string) # CIDRs for HTTPS access

  # IAM Roles
  enable_admin_role     = bool # Enable admin role
  enable_readonly_role  = bool # Enable read-only role
  enable_developer_role = bool # Enable developer role

  # Security Services
  enable_guardduty       = bool # Enable GuardDuty
  enable_securityhub     = bool # Enable Security Hub
  enable_config          = bool # Enable AWS Config
  enable_access_analyzer = bool # Enable Access Analyzer

  # S3 Buckets
  create_data_bucket = bool # Create data bucket

  # Custom Tags
  tags = map(string) # Additional tags
}
```

### Example Configurations

#### Development Account (Cost-Optimized)
```terraform
dev = {
  name               = "Development"
  email              = "aws-dev@example.com"
  ou_id              = module.organizational_units.ou_ids["nonprod"]
  environment        = "dev"
  role_name          = "OrganizationAccountAccessRole"
  vpc_cidr           = "10.1.0.0/16"
  availability_zones = ["ap-southeast-2a", "ap-southeast-2b"]
  enable_nat_gateway = true
  single_nat_gateway = true  # Single NAT for cost savings
  enable_vpn_gateway = false
  allowed_ssh_cidrs  = ["10.0.0.0/8"]
  allowed_https_cidrs = ["0.0.0.0/0"]
  enable_admin_role     = true
  enable_readonly_role  = true
  enable_developer_role = true
  enable_guardduty       = true
  enable_securityhub     = false  # Disable for cost savings
  enable_config          = false  # Disable for cost savings
  enable_access_analyzer = true
  create_data_bucket     = true
  tags = { CostCenter = "Engineering", Purpose = "Development" }
}
```

#### Production Account (High Availability)
```terraform
prod = {
  name               = "Production"
  email              = "aws-prod@example.com"
  ou_id              = module.organizational_units.ou_ids["prod"]
  environment        = "prod"
  role_name          = "OrganizationAccountAccessRole"
  vpc_cidr           = "10.10.0.0/16"
  availability_zones = ["ap-southeast-2a", "ap-southeast-2b", "ap-southeast-2c"]
  enable_nat_gateway = true
  single_nat_gateway = false  # NAT per AZ for HA
  enable_vpn_gateway = true   # VPN for on-premises
  allowed_ssh_cidrs  = ["10.0.0.0/8"]
  allowed_https_cidrs = ["0.0.0.0/0"]
  enable_admin_role     = true
  enable_readonly_role  = true
  enable_developer_role = false  # No developer access in prod
  enable_guardduty       = true
  enable_securityhub     = true
  enable_config          = true
  enable_access_analyzer = true
  create_data_bucket     = true
  tags = { CostCenter = "Operations", Purpose = "Production", Compliance = "SOC2" }
}
```

---

## Bootstrapping Details

### Bootstrap Modules

The account vending module includes six bootstrap submodules that configure baseline resources:

#### 1. VPC Module (`bootstrap/vpc`)
Creates a complete VPC infrastructure:
- **VPC**: Single VPC with specified CIDR block
- **Public Subnets**: One per AZ with auto-assign public IP
- **Private Subnets**: One per AZ without public IP
- **Internet Gateway**: For public subnet internet access
- **NAT Gateway(s)**: For private subnet internet access (configurable: single or per-AZ)
- **Route Tables**: Public and private route tables with proper associations
- **VPC Flow Logs**: Network traffic logging to CloudWatch Logs
- **DNS**: DNS hostnames and DNS support enabled

**Files**: `main.tf`, `variables.tf`, `outputs.tf`

#### 2. Security Groups Module (`bootstrap/security-groups`)
Creates baseline security groups:
- **Default Security Group**: Deny all inbound/outbound (replaces AWS default)
- **SSH Security Group**: SSH (port 22) access from specified CIDRs
- **HTTPS Security Group**: HTTPS (port 443) access from specified CIDRs
- **HTTP Security Group**: HTTP (port 80) access from specified CIDRs
- **Internal Security Group**: All traffic within VPC CIDR
- **Database Security Group**: MySQL/PostgreSQL access from VPC
- **ALB Security Group**: Application Load Balancer access

**Files**: `main.tf`, `variables.tf`, `outputs.tf`

#### 3. IAM Module (`bootstrap/iam`)
Creates cross-account IAM roles and policies:
- **Admin Role**: Full administrative access (AdministratorAccess policy)
- **ReadOnly Role**: Read-only access across all services (ReadOnlyAccess policy)
- **Developer Role**: Limited write access for developers (custom policy)
- **Terraform Role**: Infrastructure automation access (custom policy)
- **EC2 Instance Profile**: For EC2 instances to assume roles
- **Lambda Execution Role**: For Lambda functions

All roles include trust relationships with the management account for cross-account access.

**Files**: `main.tf`, `variables.tf`, `outputs.tf`

#### 4. Logging Module (`bootstrap/logging`)
Configures CloudWatch logging and monitoring:
- **Application Log Groups**: For application logs with configurable retention
- **VPC Flow Logs**: Network traffic logs with KMS encryption
- **Metric Filters**: For security events (unauthorized API calls, root usage, etc.)
- **CloudWatch Alarms**: For critical security events
- **Log Encryption**: All logs encrypted with KMS
- **Log Retention**: Configurable retention periods (default 365 days)

**Files**: `main.tf`, `variables.tf`, `outputs.tf`

#### 5. Security Module (`bootstrap/security`)
Enables AWS security services:
- **Amazon GuardDuty**: Threat detection with 15-minute finding frequency
- **AWS Security Hub**: Security posture management with CIS and AWS Foundational standards
- **AWS Config**: Resource configuration tracking with delivery to S3
- **IAM Access Analyzer**: Analyzes resource policies for external access
- **EBS Encryption**: Enables EBS encryption by default
- **S3 Public Access Block**: Blocks all public access at account level

**Files**: `main.tf`, `variables.tf`, `outputs.tf`

#### 6. S3 Module (`bootstrap/s3`)
Creates baseline S3 buckets with security configurations:
- **Logs Bucket**: 
  - Stores application and service logs
  - Lifecycle: STANDARD → STANDARD_IA (30d) → GLACIER (90d) → Delete (365d)
  - Versioning enabled
  - KMS or AES256 encryption
  - Public access blocked
  
- **Backups Bucket**:
  - Stores backups and snapshots
  - Lifecycle: STANDARD → STANDARD_IA (30d) → GLACIER (90d) → DEEP_ARCHIVE (180d) → Delete (730d)
  - Versioning enabled
  - KMS or AES256 encryption
  - Public access blocked
  - Access logging to logs bucket
  
- **Data Bucket** (optional):
  - Stores application data
  - Lifecycle: INTELLIGENT_TIERING (automatic optimization)
  - Versioning enabled
  - KMS or AES256 encryption
  - Public access blocked
  - Access logging to logs bucket

All buckets enforce HTTPS-only access and include bucket policies for secure transport.

**Files**: `main.tf`, `variables.tf`, `outputs.tf`, `README.md`

### What Gets Created in Each Account

#### 1. VPC Infrastructure
- **VPC**: Single VPC with specified CIDR
- **Public Subnets**: One per AZ, with auto-assign public IP
- **Private Subnets**: One per AZ, no public IP
- **Internet Gateway**: For public subnet internet access
- **NAT Gateway(s)**: For private subnet internet access (1 or N based on config)
- **Route Tables**: Public and private route tables with associations
- **VPC Flow Logs**: Network traffic logging to CloudWatch

#### 2. Security Groups
- **Default SG**: Deny all (replaces AWS default)
- **SSH SG**: SSH access from specified CIDRs
- **HTTPS SG**: HTTPS access from specified CIDRs
- **Internal SG**: Communication within VPC

#### 3. IAM Roles
- **Admin Role**: Full administrative access
- **ReadOnly Role**: Read-only access across services
- **Developer Role**: Developer-level permissions
- **Terraform Role**: For infrastructure automation

#### 4. Security Services
- **GuardDuty**: Threat detection
- **Security Hub**: Compliance monitoring
- **AWS Config**: Resource configuration tracking
- **Access Analyzer**: IAM policy analysis

#### 5. Logging
- **CloudWatch Log Groups**: For application logs
- **VPC Flow Logs**: Network traffic logs
- **S3 Logs Bucket**: Centralized log storage

#### 6. S3 Buckets
- **Logs Bucket**: For application and service logs
- **Backups Bucket**: For backup storage
- **Data Bucket**: For application data (optional)

#### 7. Configuration Storage
- **SSM Parameters**: Account configuration and metadata

---

## Adding New Accounts

### Step 1: Add Account to Configuration

```terraform
accounts = {
  # Existing accounts...
  
  # New account
  new_account = {
    name               = "NewAccount"
    email              = "aws-new@example.com"  # Must be unique!
    ou_id              = module.organizational_units.ou_ids["nonprod"]
    environment        = "dev"
    role_name          = "OrganizationAccountAccessRole"
    vpc_cidr           = "10.4.0.0/16"  # Must not overlap!
    availability_zones = ["ap-southeast-2a", "ap-southeast-2b"]
    enable_nat_gateway = true
    single_nat_gateway = true
    enable_vpn_gateway = false
    allowed_ssh_cidrs  = ["10.0.0.0/8"]
    allowed_https_cidrs = ["0.0.0.0/0"]
    enable_admin_role     = true
    enable_readonly_role  = true
    enable_developer_role = true
    enable_guardduty       = true
    enable_securityhub     = true
    enable_config          = true
    enable_access_analyzer = true
    create_data_bucket     = true
    tags = { CostCenter = "Engineering" }
  }
}
```

### Step 2: Plan and Apply

```bash
terraform plan
terraform apply
```

### Step 3: Verify

```bash
# Check account was created
aws organizations list-accounts

# Assume role and verify VPC
aws sts assume-role \
  --role-arn arn:aws:iam::<ACCOUNT-ID>:role/OrganizationAccountAccessRole \
  --role-session-name verify

# List VPCs
aws ec2 describe-vpcs
```

---

## Cost Considerations

### Per Account Monthly Costs

| Component | Single NAT | Multi-AZ NAT | Notes |
|-----------|------------|--------------|-------|
| NAT Gateway | ~$32 | ~$96 (3 AZs) | $0.045/hour + data |
| VPC Flow Logs | ~$0.50/GB | ~$0.50/GB | Variable |
| GuardDuty | ~$5-10 | ~$5-10 | Based on events |
| Security Hub | ~$0.001/check | ~$0.001/check | Variable |
| Config | ~$2/rule | ~$2/rule | Per rule/region |
| S3 Storage | Variable | Variable | Based on usage |
| **Total (Dev)** | **~$50-70** | **~$110-130** | Approximate |
| **Total (Prod)** | **~$70-100** | **~$130-160** | Approximate |

### Cost Optimization Tips

1. **Use Single NAT Gateway in Non-Prod**
   ```terraform
   single_nat_gateway = true  # Saves ~$64/month
   ```

2. **Disable Unnecessary Security Services in Dev**
   ```terraform
   enable_securityhub = false  # Saves ~$5/month
   enable_config      = false  # Saves ~$10/month
   ```

3. **Use S3 Lifecycle Policies**
   - Transition logs to Glacier after 90 days
   - Delete old logs after retention period

4. **Right-Size VPC CIDR**
   - Use /20 or /24 for dev accounts
   - Reserve /16 for production

---

## Security

### Email Address Requirements
- Must be unique across all AWS accounts
- Cannot be reused even after account closure
- Recommend using email aliases (e.g., aws-dev+001@example.com)

### Cross-Account Access
- Uses OrganizationAccountAccessRole by default
- Role created automatically by AWS Organizations
- Full administrative access from management account
- Consider creating least-privilege roles for day-to-day access

### Network Security
- Default security group denies all traffic
- Explicit security groups required for access
- VPC Flow Logs enabled by default
- Private subnets have no direct internet access

### Data Encryption
- All S3 buckets encrypted with KMS
- CloudWatch Logs encrypted with KMS
- EBS volumes encrypted by default (via SCP)

---

## Troubleshooting

### Account Creation Fails

**Error**: "Email address already in use"
- **Solution**: Use a unique email address
- **Tip**: Use email aliases (e.g., aws-dev+001@example.com)

**Error**: "Insufficient permissions"
- **Solution**: Ensure management account has organizations:CreateAccount permission
- **Check**: Verify you're running from management account

### Bootstrapping Fails

**Error**: "Unable to assume role"
- **Solution**: Wait 60 seconds after account creation
- **Check**: Verify OrganizationAccountAccessRole exists
- **Fix**: Increase wait time in time_sleep resource

**Error**: "VPC CIDR overlaps"
- **Solution**: Use non-overlapping CIDR blocks
- **Tip**: Plan CIDR allocation before creating accounts

### VPC Creation Fails

**Error**: "Invalid availability zone"
- **Solution**: Verify AZs are valid for the region
- **Check**: `aws ec2 describe-availability-zones`

**Error**: "Insufficient IP addresses"
- **Solution**: Use larger CIDR block (e.g., /16 instead of /24)

---

## Best Practices

### 1. Email Management
- Use a shared email system (e.g., Google Groups)
- Use email aliases for easy management
- Document email-to-account mapping

### 2. CIDR Planning
- Plan CIDR allocation before creating accounts
- Use /16 for production, /20 for non-prod
- Document CIDR assignments
- Leave room for growth

### 3. Tagging Strategy
- Use consistent tags across all accounts
- Include: CostCenter, Owner, Environment, Purpose
- Enforce tagging via SCPs

### 4. Security
- Enable all security services in production
- Use least-privilege IAM roles
- Regularly review security findings
- Enable MFA for all users

### 5. Cost Management
- Use single NAT in non-prod
- Disable unnecessary services in dev
- Set up budget alerts per account
- Review costs monthly

### 6. Operational
- Document account purpose and owner
- Store account metadata in SSM
- Automate account provisioning
- Test disaster recovery procedures

---

## References

- [AWS Organizations](https://docs.aws.amazon.com/organizations/)
- [AWS Control Tower](https://docs.aws.amazon.com/controltower/)
- [VPC Best Practices](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-best-practices.html)
- [IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)

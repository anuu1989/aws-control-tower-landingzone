# Account Vending Module

Automated AWS account creation and bootstrapping with baseline configurations.

## Features

- Automated account creation in specified OUs
- VPC with public/private subnets across multiple AZs
- Baseline security groups
- IAM roles for cross-account access
- Security services (GuardDuty, Security Hub, Config)
- CloudWatch Logs and VPC Flow Logs
- S3 buckets for logs, backups, and data
- Fully extensible account list

## Quick Start

```terraform
module "account_vending" {
  source = "./modules/account-vending"

  management_account_id  = data.aws_caller_identity.current.account_id
  home_region            = "ap-southeast-2"
  enable_bootstrapping   = true
  central_log_bucket     = "my-logs-bucket"
  kms_key_id             = module.security.kms_key_id
  security_sns_topic_arn = aws_sns_topic.security.arn

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
    Module    = "AccountVending"
  }
}
```

## Adding New Accounts

Simply add a new entry to the `accounts` map:

```terraform
accounts = {
  # Existing accounts...
  
  staging = {
    name               = "Staging"
    email              = "aws-staging@example.com"
    ou_id              = module.organizational_units.ou_ids["nonprod"]
    environment        = "staging"
    role_name          = "OrganizationAccountAccessRole"
    vpc_cidr           = "10.3.0.0/16"
    availability_zones = ["ap-southeast-2a", "ap-southeast-2b"]
    # ... rest of configuration
  }
}
```

## What Gets Created

### Per Account:
1. **AWS Account** in specified OU
2. **VPC** with:
   - Public subnets (one per AZ)
   - Private subnets (one per AZ)
   - Internet Gateway
   - NAT Gateway(s)
   - Route tables
   - VPC Flow Logs
3. **Security Groups**:
   - Default (deny all)
   - SSH access
   - HTTPS access
   - Internal communication
4. **IAM Roles**:
   - Admin role
   - ReadOnly role
   - Developer role
   - Terraform role
5. **Security Services**:
   - GuardDuty
   - Security Hub
   - AWS Config
   - Access Analyzer
6. **S3 Buckets**:
   - Logs bucket
   - Backups bucket
   - Data bucket (optional)
7. **CloudWatch**:
   - Log groups
   - VPC Flow Logs
8. **SSM Parameters**:
   - Account configuration
   - VPC details

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| accounts | Map of accounts to create | map(object) | yes |
| management_account_id | Management account ID | string | yes |
| central_log_bucket | Central S3 bucket for logs | string | yes |
| kms_key_id | KMS key for encryption | string | yes |
| security_sns_topic_arn | SNS topic for security alerts | string | yes |
| enable_bootstrapping | Enable account bootstrapping | bool | no |
| home_region | Primary AWS region | string | no |

## Outputs

| Name | Description |
|------|-------------|
| account_ids | Map of account keys to IDs |
| account_details | Detailed account information |
| vpc_ids | Map of VPC IDs |
| security_group_ids | Map of security group IDs |
| iam_role_arns | Map of IAM role ARNs |

## Cost Considerations

### Per Account Costs:
- **NAT Gateway**: ~$32/month (single) or ~$96/month (3 AZs)
- **VPC Flow Logs**: ~$0.50/GB
- **GuardDuty**: ~$5-10/month
- **Config**: ~$2/rule/month
- **S3 Storage**: Variable based on usage

### Cost Optimization:
- Use `single_nat_gateway = true` for non-prod (~$64/month savings)
- Disable unnecessary security services in dev
- Use S3 lifecycle policies for logs
- Set appropriate CloudWatch retention

## Security Best Practices

1. **Unique Emails**: Each account requires unique email
2. **Least Privilege**: Disable unnecessary IAM roles
3. **Network Segmentation**: Use different CIDR blocks
4. **Encryption**: All data encrypted with KMS
5. **Logging**: All activities logged to CloudWatch
6. **Monitoring**: Security services enabled by default

## Troubleshooting

### Account Creation Fails
- Verify email is unique and valid
- Check OU ID exists
- Ensure sufficient permissions
- Wait 60 seconds between account creations

### Bootstrapping Fails
- Verify OrganizationAccountAccessRole exists
- Check cross-account assume role permissions
- Ensure KMS key policy allows account access
- Verify S3 bucket policy allows account access

### VPC Creation Fails
- Check CIDR doesn't overlap with existing VPCs
- Verify availability zones are valid
- Ensure sufficient IP addresses in CIDR

## Examples

See `examples/account-vending/` for complete examples.

## References

- [AWS Organizations](https://docs.aws.amazon.com/organizations/)
- [AWS Control Tower Account Factory](https://docs.aws.amazon.com/controltower/latest/userguide/account-factory.html)
- [VPC Best Practices](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-best-practices.html)

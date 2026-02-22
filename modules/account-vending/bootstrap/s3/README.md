# S3 Bootstrap Module

This module creates baseline S3 buckets with security configurations for newly created AWS accounts.

## Features

- **Logs Bucket**: Stores application and service logs with lifecycle policies
- **Backups Bucket**: Stores backups and snapshots with long-term retention
- **Data Bucket**: Optional bucket for application data with intelligent tiering
- **Security**: Encryption, versioning, public access blocking
- **Lifecycle Management**: Automatic transition to cheaper storage classes
- **Access Logging**: Logs bucket access to the logs bucket

## Buckets Created

### Logs Bucket
- **Purpose**: Store application logs, VPC flow logs, CloudWatch logs
- **Naming**: `{account_name}-logs-{account_id}`
- **Lifecycle**:
  - Day 0-30: STANDARD
  - Day 30-90: STANDARD_IA
  - Day 90+: GLACIER
  - Expiration: Configurable (default 365 days)
- **Features**: Versioning, encryption, public access blocked

### Backups Bucket
- **Purpose**: Store backups, snapshots, disaster recovery data
- **Naming**: `{account_name}-backups-{account_id}`
- **Lifecycle**:
  - Day 0-30: STANDARD
  - Day 30-90: STANDARD_IA
  - Day 90-180: GLACIER
  - Day 180+: DEEP_ARCHIVE
  - Expiration: Configurable (default 730 days)
- **Features**: Versioning, encryption, public access blocked, access logging

### Data Bucket (Optional)
- **Purpose**: Store application data
- **Naming**: `{account_name}-data-{account_id}`
- **Lifecycle**:
  - Day 0+: INTELLIGENT_TIERING (automatic optimization)
- **Features**: Versioning, encryption, public access blocked, access logging

## Security Features

All buckets include:
- **Encryption**: AES256 or KMS encryption
- **Versioning**: Enabled for data protection
- **Public Access Block**: All public access blocked
- **Secure Transport**: HTTPS required for all operations
- **Access Logging**: Bucket access logged to logs bucket

## Usage

```hcl
module "account_s3" {
  source = "./bootstrap/s3"

  account_id   = "123456789012"
  account_name = "dev-account"
  environment  = "dev"

  # Bucket creation flags
  create_logs_bucket    = true
  create_backups_bucket = true
  create_data_bucket    = false

  # Encryption
  kms_key_id = "arn:aws:kms:ap-southeast-2:123456789012:key/12345678-1234-1234-1234-123456789012"

  # Lifecycle
  logs_retention_days    = 365
  backups_retention_days = 730

  tags = {
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| account_id | AWS Account ID | string | - | yes |
| account_name | Account name (used in bucket naming) | string | - | yes |
| environment | Environment (dev, test, staging, prod) | string | - | yes |
| create_logs_bucket | Create logs bucket | bool | true | no |
| create_backups_bucket | Create backups bucket | bool | true | no |
| create_data_bucket | Create data bucket | bool | false | no |
| kms_key_id | KMS key ID for encryption | string | null | no |
| logs_retention_days | Logs retention in days | number | 365 | no |
| backups_retention_days | Backups retention in days | number | 730 | no |
| tags | Tags to apply to buckets | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| logs_bucket_id | Logs bucket ID |
| logs_bucket_arn | Logs bucket ARN |
| logs_bucket_name | Logs bucket name |
| backups_bucket_id | Backups bucket ID |
| backups_bucket_arn | Backups bucket ARN |
| backups_bucket_name | Backups bucket name |
| data_bucket_id | Data bucket ID (if created) |
| data_bucket_arn | Data bucket ARN (if created) |
| data_bucket_name | Data bucket name (if created) |
| bucket_summary | Summary of all buckets created |
| all_bucket_arns | List of all bucket ARNs |
| all_bucket_names | List of all bucket names |

## Cost Optimization

- Use lifecycle policies to transition to cheaper storage classes
- Enable intelligent tiering for data bucket
- Set appropriate retention periods
- Consider single NAT gateway for non-production accounts
- Use AWS managed keys instead of KMS for lower costs

## Best Practices

1. **Encryption**: Always use encryption (KMS for sensitive data)
2. **Versioning**: Keep versioning enabled for data protection
3. **Lifecycle**: Configure appropriate lifecycle policies
4. **Monitoring**: Enable CloudWatch metrics and alarms
5. **Access Logging**: Enable access logging for audit trails
6. **Backup**: Regular backups to backups bucket
7. **Retention**: Set retention based on compliance requirements

## Notes

- Bucket names must be globally unique
- Account name should be lowercase with hyphens only
- KMS encryption adds cost but provides better control
- Lifecycle transitions are automatic based on object age
- Access logs are stored in the logs bucket

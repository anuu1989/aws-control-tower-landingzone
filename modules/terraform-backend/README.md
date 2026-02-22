# Terraform Backend Module

Reusable module for creating Terraform backend infrastructure with S3 state storage.

## Features

- ✅ **No DynamoDB Required**: Uses Terraform 1.6+ native S3 state locking
- ✅ **KMS Encryption**: Automatic encryption at rest with key rotation
- ✅ **Versioning**: Keep history of all state changes
- ✅ **Lifecycle Policies**: Automatic cleanup and cost optimization
- ✅ **Access Logging**: Optional S3 access logs
- ✅ **Monitoring**: Optional CloudWatch alarms and EventBridge rules
- ✅ **Security**: Public access blocked, TLS required
- ✅ **IAM Policy**: Optional policy for backend access

## Terraform 1.6+ State Locking

Starting with Terraform 1.6.0, S3 backend supports native state locking without DynamoDB:

- Uses S3 conditional writes for locking
- No additional infrastructure required
- Lower cost (no DynamoDB charges)
- Simpler architecture
- Same reliability as DynamoDB locking

## Usage

### Basic Example

```hcl
module "terraform_backend" {
  source = "./modules/terraform-backend"

  name_prefix       = "my-project"
  state_bucket_name = "my-org-terraform-state"
  
  allowed_principals = [
    "arn:aws:iam::123456789012:root"
  ]

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

### With All Features

```hcl
module "terraform_backend" {
  source = "./modules/terraform-backend"

  name_prefix       = "control-tower"
  state_bucket_name = "my-org-control-tower-terraform-state"
  
  # Access control
  allowed_principals = [
    "arn:aws:iam::123456789012:root",
    "arn:aws:iam::123456789012:role/TerraformRole"
  ]
  
  # Retention
  state_retention_days = 90
  logs_retention_days  = 365
  
  # Features
  enable_logging    = true
  enable_monitoring = true
  create_iam_policy = true
  
  # Monitoring
  alarm_sns_topic_arn         = aws_sns_topic.alerts.arn
  state_bucket_size_threshold = 10737418240 # 10 GB
  
  # KMS
  kms_deletion_window = 30
  
  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
    Project     = "control-tower"
  }
}
```

### Initialize Terraform with Backend

After deploying the module:

```bash
# Get backend configuration
terraform output -raw backend_config_hcl > backend.hcl

# Initialize with backend
terraform init -backend-config=backend.hcl
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.6.0 |
| aws | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name_prefix | Prefix for resource names | `string` | n/a | yes |
| state_bucket_name | S3 bucket name (globally unique) | `string` | n/a | yes |
| allowed_principals | AWS principals allowed to access state | `list(string)` | `[]` | no |
| kms_deletion_window | KMS key deletion window (days) | `number` | `30` | no |
| state_retention_days | State version retention (days) | `number` | `90` | no |
| logs_retention_days | Access log retention (days) | `number` | `365` | no |
| state_bucket_size_threshold | Bucket size alarm threshold (bytes) | `number` | `10737418240` | no |
| enable_logging | Enable S3 access logging | `bool` | `true` | no |
| enable_monitoring | Enable CloudWatch monitoring | `bool` | `true` | no |
| create_iam_policy | Create IAM policy for access | `bool` | `true` | no |
| alarm_sns_topic_arn | SNS topic for alarms | `string` | `""` | no |
| tags | Tags to apply to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| state_bucket_name | S3 bucket name |
| state_bucket_arn | S3 bucket ARN |
| state_bucket_region | S3 bucket region |
| kms_key_id | KMS key ID |
| kms_key_arn | KMS key ARN |
| kms_key_alias | KMS key alias |
| backend_policy_arn | IAM policy ARN |
| logs_bucket_name | Logs bucket name |
| backend_config | Backend configuration object |
| backend_config_hcl | Backend configuration in HCL |

## Resources Created

- `aws_s3_bucket` - State storage bucket
- `aws_s3_bucket_versioning` - Enable versioning
- `aws_s3_bucket_server_side_encryption_configuration` - KMS encryption
- `aws_s3_bucket_public_access_block` - Block public access
- `aws_s3_bucket_logging` - Access logging (optional)
- `aws_s3_bucket_lifecycle_configuration` - Lifecycle policies
- `aws_s3_bucket_policy` - Bucket policy
- `aws_s3_bucket` - Logs bucket (optional)
- `aws_kms_key` - Encryption key
- `aws_kms_alias` - Key alias
- `aws_cloudwatch_metric_alarm` - Monitoring alarms (optional)
- `aws_cloudwatch_event_rule` - State change events (optional)
- `aws_iam_policy` - Backend access policy (optional)

## Security

### Encryption
- KMS encryption at rest
- Automatic key rotation
- TLS required for all access

### Access Control
- Public access blocked
- IAM-based access control
- Bucket policy enforcement

### Monitoring
- CloudWatch alarms for bucket size
- EventBridge rules for state changes
- Access logging (optional)

## Cost Optimization

### Storage Lifecycle
- 0-30 days: Standard storage
- 30-90 days: Standard-IA
- 90-180 days: Glacier Instant Retrieval
- 180+ days: Deep Archive

### Retention
- State versions: 90 days (configurable)
- Access logs: 365 days (configurable)
- Automatic cleanup of old versions

### Estimated Monthly Cost
- S3 Storage: ~$0.023/GB
- KMS: $1/month + $0.03/10K requests
- CloudWatch: Minimal
- **Total: $5-10/month** (typical usage)

## Migration from DynamoDB Backend

If you're migrating from a DynamoDB-based backend:

```bash
# 1. Deploy new backend module
terraform apply

# 2. Update backend configuration (remove dynamodb_table)
# Old:
# backend "s3" {
#   bucket         = "my-bucket"
#   dynamodb_table = "my-locks"  # Remove this
# }

# New:
# backend "s3" {
#   bucket = "my-bucket"
# }

# 3. Reinitialize
terraform init -migrate-state

# 4. (Optional) Delete old DynamoDB table
aws dynamodb delete-table --table-name my-locks
```

## Examples

See `examples/terraform-backend/` for complete examples:
- Basic backend setup
- Multi-environment setup
- With monitoring and logging

## Best Practices

1. **Unique Bucket Names**: Use organization prefix
2. **Enable Versioning**: Always keep state history
3. **Enable Logging**: Track access patterns
4. **Set Retention**: Balance cost and compliance
5. **Monitor Size**: Set appropriate alarms
6. **Restrict Access**: Use least privilege IAM
7. **Enable Encryption**: Use KMS with rotation
8. **Tag Resources**: For cost tracking

## Troubleshooting

### State Lock Timeout

Terraform 1.6+ uses S3 conditional writes. If you see lock errors:

```bash
# Check for lock file
aws s3 ls s3://your-bucket/.terraform.lock.info

# Remove stale lock (use with caution!)
aws s3 rm s3://your-bucket/.terraform.lock.info
```

### Access Denied

1. Verify IAM permissions
2. Check bucket policy
3. Verify KMS key policy
4. Ensure principal is in `allowed_principals`

## References

- [Terraform 1.6 Release Notes](https://github.com/hashicorp/terraform/releases/tag/v1.6.0)
- [S3 Backend Documentation](https://www.terraform.io/docs/language/settings/backends/s3.html)
- [AWS S3 Best Practices](https://docs.aws.amazon.com/AmazonS3/latest/userguide/security-best-practices.html)

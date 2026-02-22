# Terraform Backend Configuration Guide

Complete guide for setting up and managing Terraform backend infrastructure for AWS Control Tower Landing Zone.

## Overview

The Terraform backend stores state files remotely in S3 with DynamoDB for state locking. This enables:

- **Team Collaboration**: Multiple team members can work on the same infrastructure
- **State Locking**: Prevents concurrent modifications
- **State History**: Versioning keeps track of all changes
- **Security**: Encryption at rest and in transit
- **Disaster Recovery**: Point-in-time recovery and backups

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                  Terraform Backend                           │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  S3 Bucket                                            │  │
│  │  • Versioning: Enabled                                │  │
│  │  • Encryption: KMS (aws:kms)                          │  │
│  │  • Public Access: Blocked                             │  │
│  │  • Logging: Enabled                                   │  │
│  │  • Lifecycle: 90-day retention                        │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  DynamoDB Table                                       │  │
│  │  • Billing: Pay-per-request                           │  │
│  │  • PITR: Enabled                                      │  │
│  │  • Encryption: KMS                                    │  │
│  │  • Hash Key: LockID                                   │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  KMS Key                                              │  │
│  │  • Rotation: Automatic                                │  │
│  │  • Deletion Window: 30 days                           │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## Quick Start

### Automated Setup (Recommended)

```bash
# Run automated setup script
./scripts/setup-backend.sh
```

The script will:
1. Check prerequisites
2. Validate configuration
3. Deploy backend infrastructure
4. Generate backend.hcl configuration
5. Provide next steps

### Manual Setup

#### Step 1: Configure Backend

```bash
cd backend
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars
```

Required configuration:
```hcl
state_bucket_name = "your-org-control-tower-terraform-state"  # Must be globally unique
allowed_account_ids = ["arn:aws:iam::123456789012:root"]
region = "ap-southeast-2"
```

#### Step 2: Deploy Backend

```bash
terraform init
terraform plan
terraform apply
```

#### Step 3: Save Configuration

```bash
# Save backend config
terraform output -json backend_config > ../backend-config.json

# Display configuration
terraform output backend_config
```

#### Step 4: Initialize Main Terraform

```bash
cd ..
terraform init -backend-config=backend.hcl
```

## Configuration Options

### Backend Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `state_bucket_name` | S3 bucket name (globally unique) | - | Yes |
| `lock_table_name` | DynamoDB table name | `terraform-state-locks` | No |
| `allowed_account_ids` | AWS account IDs for access | `[]` | Yes |
| `region` | AWS region | `ap-southeast-2` | No |
| `kms_deletion_window` | KMS key deletion window (days) | `30` | No |
| `state_retention_days` | State version retention (days) | `90` | No |
| `logs_retention_days` | Access log retention (days) | `365` | No |

### Backend Configuration File

Create `backend.hcl`:

```hcl
bucket         = "your-org-control-tower-terraform-state"
key            = "control-tower/terraform.tfstate"
region         = "ap-southeast-2"
encrypt        = true
kms_key_id     = "arn:aws:kms:ap-southeast-2:123456789012:key/..."
dynamodb_table = "control-tower-terraform-locks"
```

## Usage

### Initialize with Backend

```bash
# First time initialization
terraform init -backend-config=backend.hcl

# Reconfigure backend
terraform init -reconfigure -backend-config=backend.hcl

# Migrate from local to remote state
terraform init -migrate-state -backend-config=backend.hcl
```

### State Operations

```bash
# List resources in state
terraform state list

# Show specific resource
terraform state show aws_s3_bucket.example

# Pull current state
terraform state pull > terraform.tfstate.backup

# Push state (use with caution!)
terraform state push terraform.tfstate
```

### State Locking

```bash
# Check for locks
aws dynamodb scan --table-name control-tower-terraform-locks

# Force unlock (emergency only!)
terraform force-unlock <lock-id>
```

## Security

### Encryption

- **At Rest**: KMS encryption for S3 and DynamoDB
- **In Transit**: TLS 1.2+ required for all access
- **Key Rotation**: Automatic KMS key rotation enabled

### Access Control

```hcl
# IAM policy for backend access
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::your-bucket",
        "arn:aws:s3:::your-bucket/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem"
      ],
      "Resource": "arn:aws:dynamodb:region:account:table/locks"
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt",
        "kms:Encrypt",
        "kms:GenerateDataKey"
      ],
      "Resource": "arn:aws:kms:region:account:key/key-id"
    }
  ]
}
```

### Best Practices

1. **Restrict Access**
   - Use IAM roles with least privilege
   - Enable MFA for state access
   - Limit `allowed_account_ids`

2. **Enable Logging**
   - S3 access logs
   - CloudTrail API logging
   - EventBridge for state changes

3. **Regular Backups**
   - Automated versioning
   - Manual backups before major changes
   - Test restore procedures

4. **Monitor Activity**
   - CloudWatch alarms
   - Review access logs
   - Track state changes

## Monitoring

### CloudWatch Alarms

1. **State Bucket Size**
   - Threshold: 10 GB
   - Action: SNS notification

2. **DynamoDB Throttles**
   - Threshold: 5 errors
   - Action: SNS notification

### Metrics to Track

- S3 bucket size
- Number of state versions
- DynamoDB read/write capacity
- KMS key usage
- Failed access attempts

## Backup and Recovery

### Backup State

```bash
# Download current state
aws s3 cp s3://your-bucket/control-tower/terraform.tfstate ./backup/

# List all versions
aws s3api list-object-versions \
  --bucket your-bucket \
  --prefix control-tower/terraform.tfstate
```

### Restore State

```bash
# Restore specific version
aws s3api get-object \
  --bucket your-bucket \
  --key control-tower/terraform.tfstate \
  --version-id <version-id> \
  ./restored-state.tfstate

# Upload restored state
terraform state push ./restored-state.tfstate
```

### Disaster Recovery

1. **State File Corruption**
   ```bash
   # Restore from version
   aws s3api get-object \
     --bucket your-bucket \
     --key control-tower/terraform.tfstate \
     --version-id <previous-version> \
     ./terraform.tfstate
   
   terraform state push ./terraform.tfstate
   ```

2. **Bucket Deletion**
   - Restore from backup
   - Recreate backend infrastructure
   - Push state from backup

3. **Lock Table Issues**
   - Force unlock if needed
   - Recreate table if corrupted
   - Restore from PITR

## Troubleshooting

### Common Issues

**Issue**: State lock timeout
```bash
# Check locks
aws dynamodb scan --table-name control-tower-terraform-locks

# Force unlock
terraform force-unlock <lock-id>
```

**Issue**: Access denied
```bash
# Verify IAM permissions
aws iam get-user
aws iam list-attached-user-policies --user-name <username>

# Check bucket policy
aws s3api get-bucket-policy --bucket your-bucket
```

**Issue**: Encryption errors
```bash
# Verify KMS key
aws kms describe-key --key-id <key-id>

# Check key policy
aws kms get-key-policy --key-id <key-id> --policy-name default
```

## Migration

### From Local to Remote State

```bash
# 1. Deploy backend infrastructure
cd backend && terraform apply

# 2. Initialize with backend
cd .. && terraform init -migrate-state -backend-config=backend.hcl

# 3. Verify migration
terraform state list
```

### Between Backends

```bash
# 1. Pull current state
terraform state pull > old-state.tfstate

# 2. Reconfigure backend
terraform init -reconfigure -backend-config=new-backend.hcl

# 3. Push state to new backend
terraform state push old-state.tfstate
```

## Cost Optimization

### Monthly Costs (Estimated)

- **S3 Storage**: $0.023/GB
- **S3 Requests**: Minimal
- **DynamoDB**: Pay-per-request (~$0.50/month)
- **KMS**: $1/month + $0.03/10K requests
- **Total**: $5-10/month

### Optimization Tips

1. Enable lifecycle policies
2. Use pay-per-request for DynamoDB
3. Clean up old state versions
4. Monitor bucket size

## Best Practices

1. **Always use backend for production**
2. **Never commit backend.hcl to git** (add to .gitignore)
3. **Regular state backups**
4. **Test disaster recovery procedures**
5. **Monitor backend health**
6. **Review access logs regularly**
7. **Use separate backends per environment**
8. **Document backend configuration**

## References

- [Terraform S3 Backend](https://www.terraform.io/docs/language/settings/backends/s3.html)
- [AWS S3 Best Practices](https://docs.aws.amazon.com/AmazonS3/latest/userguide/security-best-practices.html)
- [DynamoDB Best Practices](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/best-practices.html)
- [KMS Best Practices](https://docs.aws.amazon.com/kms/latest/developerguide/best-practices.html)

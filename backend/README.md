# Terraform Backend Infrastructure

This directory contains the Terraform configuration for creating the backend infrastructure (S3 bucket and DynamoDB table) used to store Terraform state.

## Overview

The backend infrastructure must be deployed **BEFORE** the main Control Tower infrastructure. 

**Uses Terraform 1.6+ with native S3 state locking - no DynamoDB required!**

It creates:

- **S3 Bucket**: Stores Terraform state files with versioning and encryption
- **KMS Key**: Encrypts state files
- **IAM Policy**: Grants access to backend resources
- **CloudWatch Alarms**: Monitors backend health
- **EventBridge Rules**: Tracks state changes
- **S3 Access Logs**: Optional access logging

**Note**: This implementation uses the `terraform-backend` module for consistency and maintainability.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│           Terraform Backend (Terraform 1.6+)                 │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  S3 Bucket (State Storage)                           │  │
│  │  • Versioning enabled                                 │  │
│  │  • KMS encryption                                     │  │
│  │  • Native state locking (no DynamoDB!)               │  │
│  │  • Public access blocked                              │  │
│  │  • Access logging enabled                             │  │
│  │  • Lifecycle policies                                 │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  KMS Key                                              │  │
│  │  • Automatic rotation                                 │  │
│  │  • 30-day deletion window                             │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Monitoring                                           │  │
│  │  • CloudWatch alarms                                  │  │
│  │  • EventBridge rules                                  │  │
│  │  • SNS notifications (optional)                       │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## Prerequisites

- AWS CLI configured with management account credentials
- **Terraform >= 1.6.0** (for native S3 state locking)
- Administrator access to AWS account
- Unique S3 bucket name (globally unique across all AWS accounts)

## Deployment Steps

### Step 1: Configure Variables

```bash
# Copy example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit configuration
vim terraform.tfvars
```

Required variables:
- `state_bucket_name`: Globally unique S3 bucket name
- `allowed_account_ids`: AWS account IDs that can access the state
- `region`: AWS region for backend resources

### Step 2: Initialize Terraform

```bash
cd backend
terraform init
```

### Step 3: Review Plan

```bash
terraform plan
```

Review the resources that will be created:
- S3 bucket for state storage (with native locking)
- S3 bucket for access logs
- KMS key for encryption
- IAM policy for access
- CloudWatch alarms
- EventBridge rules

**Note**: No DynamoDB table needed with Terraform 1.6+!

### Step 4: Deploy Backend

```bash
terraform apply
```

Type `yes` to confirm deployment.

### Step 5: Save Outputs

```bash
# Save backend configuration in HCL format
terraform output -raw backend_config_hcl > ../backend.hcl

# Or save as JSON
terraform output -json backend_config > ../backend-config.json

# Display configuration
terraform output backend_config
```

## Using the Backend

After deploying the backend infrastructure, configure your main Terraform code to use it.

### Option 1: Backend Configuration File

Create `backend.hcl` in your main Terraform directory:

```hcl
bucket     = "your-org-control-tower-terraform-state"
key        = "control-tower/terraform.tfstate"
region     = "ap-southeast-2"
encrypt    = true
kms_key_id = "arn:aws:kms:ap-southeast-2:123456789012:key/12345678-1234-1234-1234-123456789012"
# Note: No dynamodb_table needed with Terraform 1.6+!
```

Initialize with backend config:

```bash
terraform init -backend-config=backend.hcl
```

### Option 2: Inline Backend Configuration

Add to your `versions.tf`:

```hcl
terraform {
  backend "s3" {
    bucket     = "your-org-control-tower-terraform-state"
    key        = "control-tower/terraform.tfstate"
    region     = "ap-southeast-2"
    encrypt    = true
    kms_key_id = "arn:aws:kms:ap-southeast-2:123456789012:key/12345678-1234-1234-1234-123456789012"
    # No dynamodb_table needed with Terraform 1.6+!
  }
}
```

Then initialize:

```bash
terraform init
```

## Features

### Security

- ✅ **Encryption at Rest**: KMS encryption for S3 and DynamoDB
- ✅ **Encryption in Transit**: TLS required for all access
- ✅ **Versioning**: State file versioning enabled
- ✅ **Public Access Blocked**: No public access to state bucket
- ✅ **Access Logging**: All access logged to separate bucket
- ✅ **State Locking**: Prevents concurrent modifications
- ✅ **IAM Policies**: Least privilege access control

### Reliability

- ✅ **Point-in-Time Recovery**: DynamoDB PITR enabled
- ✅ **Versioning**: Keep old state versions
- ✅ **Lifecycle Policies**: Automatic cleanup of old versions
- ✅ **Monitoring**: CloudWatch alarms for issues
- ✅ **Event Tracking**: EventBridge rules for state changes

### Cost Optimization

- ✅ **Pay-per-Request**: DynamoDB billing mode
- ✅ **Lifecycle Transitions**: Move old versions to cheaper storage
- ✅ **Automatic Cleanup**: Delete old versions after retention period

## Monitoring

### CloudWatch Alarms

1. **State Bucket Size**: Alerts when bucket exceeds threshold
2. **DynamoDB Throttles**: Alerts on lock table throttling

### EventBridge Rules

1. **State Changes**: Tracks PutObject and DeleteObject events

### Metrics to Monitor

- S3 bucket size
- Number of state versions
- DynamoDB read/write capacity
- KMS key usage
- Access patterns

## Maintenance

### Backup State File

```bash
# Download current state
aws s3 cp s3://your-bucket/control-tower/terraform.tfstate ./backup/

# List all versions
aws s3api list-object-versions \
  --bucket your-bucket \
  --prefix control-tower/terraform.tfstate
```

### Restore State File

```bash
# Restore specific version
aws s3api get-object \
  --bucket your-bucket \
  --key control-tower/terraform.tfstate \
  --version-id <version-id> \
  ./restored-state.tfstate

# Upload restored state
aws s3 cp ./restored-state.tfstate \
  s3://your-bucket/control-tower/terraform.tfstate
```

### Clean Up Old Versions

Lifecycle policies automatically clean up old versions after the retention period. To manually clean up:

```bash
# List old versions
aws s3api list-object-versions \
  --bucket your-bucket \
  --prefix control-tower/terraform.tfstate \
  --query 'Versions[?IsLatest==`false`]'

# Delete specific version
aws s3api delete-object \
  --bucket your-bucket \
  --key control-tower/terraform.tfstate \
  --version-id <version-id>
```

## Troubleshooting

### Issue: State Lock Timeout

**Symptom**: Terraform hangs waiting for state lock

**Solution**:
```bash
# Check lock table
aws dynamodb scan --table-name control-tower-terraform-locks

# Force unlock (use with caution!)
terraform force-unlock <lock-id>
```

### Issue: Access Denied

**Symptom**: Permission errors accessing state

**Solution**:
1. Verify IAM permissions
2. Check bucket policy
3. Verify KMS key policy
4. Ensure account ID is in `allowed_account_ids`

### Issue: Encryption Errors

**Symptom**: KMS encryption/decryption errors

**Solution**:
1. Verify KMS key exists
2. Check KMS key policy
3. Ensure IAM role has KMS permissions
4. Verify key is in correct region

## Security Best Practices

1. **Restrict Access**
   - Use IAM policies with least privilege
   - Limit `allowed_account_ids` to necessary accounts
   - Enable MFA for state access

2. **Enable Logging**
   - CloudTrail for API calls
   - S3 access logs
   - EventBridge for state changes

3. **Regular Audits**
   - Review access logs
   - Check for unauthorized access
   - Validate IAM permissions

4. **Backup Strategy**
   - Regular state backups
   - Test restore procedures
   - Document recovery process

5. **Encryption**
   - Use KMS for encryption
   - Enable key rotation
   - Secure key access

## Cost Estimation

### Monthly Costs (Approximate)

- **S3 Storage**: $0.023/GB (Standard)
- **S3 Requests**: Minimal (GET/PUT operations)
- **DynamoDB**: Pay-per-request (minimal cost for locking)
- **KMS**: $1/month per key + $0.03 per 10,000 requests
- **CloudWatch**: Minimal (alarms and logs)

**Estimated Total**: $5-10/month for typical usage

## Outputs

| Output | Description |
|--------|-------------|
| `state_bucket_name` | S3 bucket name for state storage |
| `state_bucket_arn` | S3 bucket ARN |
| `lock_table_name` | DynamoDB table name for locking |
| `lock_table_arn` | DynamoDB table ARN |
| `kms_key_id` | KMS key ID for encryption |
| `kms_key_arn` | KMS key ARN |
| `backend_policy_arn` | IAM policy ARN for backend access |
| `backend_config` | Complete backend configuration |

## Destroying Backend

⚠️ **WARNING**: Destroying the backend will delete all state files and history!

Before destroying:
1. Backup all state files
2. Ensure no active Terraform operations
3. Document all resources

```bash
# Backup state
aws s3 sync s3://your-bucket ./state-backup/

# Destroy backend (requires confirmation)
terraform destroy
```

## References

- [Terraform S3 Backend](https://www.terraform.io/docs/language/settings/backends/s3.html)
- [AWS S3 Best Practices](https://docs.aws.amazon.com/AmazonS3/latest/userguide/security-best-practices.html)
- [DynamoDB Best Practices](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/best-practices.html)
- [KMS Best Practices](https://docs.aws.amazon.com/kms/latest/developerguide/best-practices.html)

# Terraform Backend Example

Example usage of the Terraform Backend module with Terraform 1.6+ (no DynamoDB required).

## Features

- ✅ S3 backend with native state locking (Terraform 1.6+)
- ✅ No DynamoDB table needed
- ✅ KMS encryption with automatic rotation
- ✅ Versioning and lifecycle policies
- ✅ Optional access logging
- ✅ Optional CloudWatch monitoring
- ✅ IAM policy for backend access

## Usage

### 1. Configure Variables

```bash
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars
```

Required changes:
- Set unique `state_bucket_name`
- Add your AWS account ARN to `allowed_principals`

### 2. Deploy Backend

```bash
terraform init
terraform plan
terraform apply
```

### 3. Save Backend Configuration

```bash
# Save to file
terraform output -raw backend_config_hcl > ../../backend.hcl

# Or view configuration
terraform output backend_config
```

### 4. Use Backend in Main Terraform

```bash
cd ../..
terraform init -backend-config=backend.hcl
```

## Backend Configuration

The module outputs a backend configuration:

```hcl
bucket     = "your-org-control-tower-terraform-state"
key        = "terraform.tfstate"
region     = "ap-southeast-2"
encrypt    = true
kms_key_id = "arn:aws:kms:ap-southeast-2:123456789012:key/..."
```

## Terraform 1.6+ State Locking

No DynamoDB table is required! Terraform 1.6+ uses S3 conditional writes for state locking:

- Simpler architecture
- Lower cost (no DynamoDB charges)
- Same reliability
- Automatic lock management

## Cost Estimate

- S3 Storage: ~$0.023/GB
- KMS: $1/month + $0.03/10K requests
- CloudWatch: Minimal
- **Total: $5-10/month**

## Outputs

- `state_bucket_name` - S3 bucket name
- `state_bucket_arn` - S3 bucket ARN
- `kms_key_id` - KMS key ID
- `kms_key_arn` - KMS key ARN
- `backend_policy_arn` - IAM policy ARN
- `backend_config` - Backend configuration object
- `backend_config_hcl` - Backend configuration in HCL format

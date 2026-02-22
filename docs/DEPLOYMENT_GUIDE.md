# AWS Control Tower Landing Zone - Deployment Guide

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Pre-Deployment](#pre-deployment)
3. [Deployment](#deployment)
4. [Post-Deployment](#post-deployment)
5. [Troubleshooting](#troubleshooting)

## Prerequisites

### AWS Account Requirements
- AWS Organizations enabled in management account
- No existing Control Tower deployment (or plan to update existing)
- Minimum 2 email addresses for Log Archive and Audit accounts
- Access to management account with administrator permissions

### IAM Permissions Required
The deploying user/role needs:
- `AWSControlTowerServiceRolePolicy`
- `AWSOrganizationsFullAccess`
- `IAMFullAccess`
- `CloudFormationFullAccess`
- `AmazonS3FullAccess` (for Terraform state)

### Tools Required
- Terraform >= 1.5.0
- AWS CLI >= 2.0
- jq (for pre-deployment script)
- Git (recommended)

### Service Quotas to Verify
- Organizations: Organizational Units (default: 1000)
- Organizations: Accounts (default: 10, increase if needed)
- Organizations: Service Control Policies (default: 1000)
- Control Tower: Landing Zones per region (default: 1)

## Pre-Deployment

### 1. Clone Repository
```bash
git clone <repository-url>
cd control-tower-infrastructure
```

### 2. Configure Backend
Edit `versions.tf` and configure S3 backend:

```hcl
backend "s3" {
  bucket         = "your-terraform-state-bucket"
  key            = "control-tower/terraform.tfstate"
  region         = "ap-southeast-2"
  encrypt        = true
  dynamodb_table = "terraform-state-lock"
  kms_key_id     = "arn:aws:kms:ap-southeast-2:ACCOUNT_ID:key/KEY_ID"
}
```

### 3. Create State Bucket
```bash
# Create S3 bucket for state
aws s3 mb s3://your-terraform-state-bucket --region ap-southeast-2

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket your-terraform-state-bucket \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket your-terraform-state-bucket \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "aws:kms",
        "KMSMasterKeyID": "arn:aws:kms:ap-southeast-2:ACCOUNT_ID:key/KEY_ID"
      }
    }]
  }'

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region ap-southeast-2
```

### 4. Configure Variables
```bash
# Copy example configuration
cp terraform.tfvars.production terraform.tfvars

# Edit configuration
vim terraform.tfvars
```

Key variables to customize:
- `project_name`: Your project identifier
- `environment`: Environment name
- `notification_emails`: Email addresses for alerts
- `organizational_units`: Define your OU structure
- `ou_scp_policies`: Assign SCPs to each OU

### 5. Run Pre-Deployment Checks
```bash
./scripts/pre-deployment-check.sh
```

This validates:
- AWS CLI and Terraform installation
- AWS credentials and permissions
- Organizations setup
- Management account access
- Terraform configuration validity

## Deployment

### 1. Initialize Terraform
```bash
terraform init
```

### 2. Review Plan
```bash
terraform plan -out=tfplan

# Review the plan carefully
# Verify:
# - Correct number of OUs
# - SCP policies and attachments
# - Region configuration
# - Tags and naming
```

### 3. Apply Configuration
```bash
terraform apply tfplan
```

**Expected Duration**: 60-90 minutes for initial Control Tower setup

### 4. Monitor Deployment
- Watch CloudFormation stacks in AWS Console
- Monitor Control Tower setup progress
- Check for any errors in Terraform output

### 5. Save Outputs
```bash
terraform output -json > deployment-outputs.json
```

## Post-Deployment

### 1. Run Post-Deployment Script
```bash
./scripts/post-deployment.sh
```

### 2. Verify Control Tower Setup
```bash
# Check landing zone status
aws controltower list-landing-zones

# Verify OUs
aws organizations list-organizational-units-for-parent \
  --parent-id $(aws organizations list-roots --query 'Roots[0].Id' --output text)

# Check SCPs
aws organizations list-policies --filter SERVICE_CONTROL_POLICY
```

### 3. Configure AWS SSO
1. Navigate to AWS IAM Identity Center (SSO)
2. Choose identity source (AWS SSO directory or external IdP)
3. Create permission sets:
   - `AdministratorAccess` for admins
   - `PowerUserAccess` for developers
   - `ReadOnlyAccess` for auditors
4. Assign users/groups to accounts

### 4. Enable Security Services

#### GuardDuty
```bash
# Enable in all regions
for region in ap-southeast-2 ap-southeast-1 us-east-1; do
  aws guardduty create-detector \
    --enable \
    --finding-publishing-frequency FIFTEEN_MINUTES \
    --region $region
done
```

#### Security Hub
```bash
# Enable Security Hub with standards
for region in ap-southeast-2 ap-southeast-1 us-east-1; do
  aws securityhub enable-security-hub \
    --enable-default-standards \
    --region $region
done
```

#### AWS Config
```bash
# Config is typically enabled by Control Tower
# Verify it's running
aws configservice describe-configuration-recorders
```

### 5. Set Up Account Factory
1. Navigate to Service Catalog
2. Configure Account Factory product
3. Define account baselines
4. Test account provisioning

### 6. Configure Monitoring
- Set up CloudWatch dashboards
- Configure SNS topic subscriptions
- Enable CloudWatch Logs Insights
- Set up AWS Backup

### 7. Cost Management
```bash
# Enable Cost Explorer
aws ce enable-cost-explorer

# Create budget
aws budgets create-budget \
  --account-id $(aws sts get-caller-identity --query Account --output text) \
  --budget file://budget.json \
  --notifications-with-subscribers file://notifications.json
```

## Troubleshooting

### Common Issues

#### 1. "Control Tower already exists"
**Solution**: 
- Review existing Control Tower configuration
- Consider using `terraform import` for existing resources
- Or plan to update existing landing zone

#### 2. "Insufficient permissions"
**Solution**:
- Verify IAM permissions listed in prerequisites
- Ensure running from management account
- Check service control policies aren't blocking actions

#### 3. "Service quota exceeded"
**Solution**:
- Request quota increase via AWS Support
- Common quotas: Accounts, OUs, SCPs

#### 4. "Region not supported"
**Solution**:
- Verify Control Tower supports your home region
- Ensure us-east-1 is in governed regions (required)

#### 5. Terraform state lock issues
**Solution**:
```bash
# Force unlock (use with caution)
terraform force-unlock <LOCK_ID>
```

### Rollback Procedure

If deployment fails:

```bash
# 1. Review error messages
terraform show

# 2. Attempt targeted destroy of failed resources
terraform destroy -target=<resource>

# 3. Full rollback (if necessary)
terraform destroy

# 4. Clean up manually created resources
# - CloudFormation stacks
# - Service Catalog products
# - SSO configuration
```

### Getting Help

1. Check AWS Control Tower documentation
2. Review CloudFormation stack events
3. Check CloudWatch Logs
4. Contact AWS Support for Control Tower issues
5. Review Terraform state: `terraform show`

## Maintenance

### Updating Landing Zone
```bash
# Update landing_zone_version in terraform.tfvars
terraform plan
terraform apply
```

### Adding New OUs
```bash
# Edit terraform.tfvars
# Add new OU to organizational_units
# Add SCP policies to ou_scp_policies
terraform plan
terraform apply
```

### Modifying SCPs
```bash
# Edit modules/scp-policies/main.tf
# Or adjust ou_scp_policies in terraform.tfvars
terraform plan
terraform apply
```

### Disaster Recovery
- Terraform state is backed up in S3 with versioning
- Control Tower configuration is in CloudFormation
- Regular backups of account metadata recommended
- Document manual configurations outside Terraform

## Security Best Practices

1. **State File Security**
   - Encrypt state with KMS
   - Enable S3 versioning
   - Restrict access with IAM policies
   - Enable S3 access logging

2. **Credential Management**
   - Use IAM roles, not access keys
   - Enable MFA for privileged operations
   - Rotate credentials regularly
   - Use AWS SSO for human access

3. **Audit and Compliance**
   - Enable CloudTrail in all regions
   - Review SCP policies regularly
   - Monitor Security Hub findings
   - Conduct regular access reviews

4. **Change Management**
   - Use Git for version control
   - Require pull request reviews
   - Test in non-prod first
   - Document all changes

## Next Steps

After successful deployment:
1. Review [POST_DEPLOYMENT.md](POST_DEPLOYMENT.md)
2. Set up account baselines
3. Create member accounts
4. Implement network architecture
5. Deploy workload-specific infrastructure
6. Conduct security assessment
7. Train team on Control Tower operations

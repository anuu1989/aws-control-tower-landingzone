---
layout: default
title: Quick Reference
nav_order: 98
---

# Quick Reference Card
{: .no_toc }

Quick reference for common tasks and commands.
{: .fs-6 .fw-300 }

---

## 🚀 Quick Start

```bash
# Setup
./scripts/setup-pre-commit.sh
./scripts/setup-git-secrets.sh

# Deploy backend
cd examples/terraform-backend && terraform apply

# Deploy Control Tower
terraform init -backend-config=backend.hcl
make plan && make apply
```

---

## 📋 Common Commands

### Terraform

```bash
# Initialize
terraform init

# Plan
terraform plan -out=tfplan

# Apply
terraform apply tfplan

# Destroy
terraform destroy

# Format
terraform fmt -recursive

# Validate
terraform validate

# Show state
terraform show

# List resources
terraform state list
```

### Make Commands

```bash
make init          # Initialize Terraform
make validate      # Validate configuration
make plan          # Generate plan
make apply         # Apply changes
make destroy       # Destroy infrastructure
make test-all      # Run all tests
make security-scan # Run security scan
make pre-deploy    # Pre-deployment checks
```

### Testing

```bash
# All tests
make test-all

# Unit tests
make test-unit

# OPA tests
make test-opa

# Security scan
make security-scan

# Linting
make lint
```

---

## 🔧 Scripts

```bash
# Pre-commit hooks
./scripts/setup-pre-commit.sh

# Git secrets
./scripts/setup-git-secrets.sh

# State backup
./scripts/backup-state-automated.sh bucket-name

# Pre-deployment check
./scripts/pre-deployment-check.sh

# Post-deployment
./scripts/post-deployment.sh

# Validation
./scripts/validate-all.sh

# OPA tests
./scripts/run-opa-tests.sh

# Terraform tests
./scripts/run-terraform-tests.sh
```

---

## 📚 Documentation

| Document | Purpose |
|----------|---------|
| [Getting Started](getting-started.html) | Initial setup |
| [Architecture](architecture.html) | System design |
| [Deployment Guide](DEPLOYMENT_GUIDE.html) | Step-by-step deployment |
| [Security](SECURITY.html) | Security features |
| [Networking](NETWORKING.html) | Network architecture |
| [Account Vending](ACCOUNT_VENDING.html) | Account creation |
| [Disaster Recovery](DISASTER_RECOVERY.html) | DR procedures |
| [Testing](TESTING.html) | Testing guide |

---

## 🔍 Troubleshooting

### Backend Issues

```bash
# Reinitialize backend
terraform init -reconfigure

# Migrate state
terraform init -migrate-state

# Force unlock
terraform force-unlock LOCK_ID
```

### Validation Errors

```bash
# Format code
terraform fmt -recursive

# Validate syntax
terraform validate

# Check diagnostics
terraform validate -json
```

### State Issues

```bash
# Pull state
terraform state pull > backup.tfstate

# Push state
terraform state push backup.tfstate

# Remove resource
terraform state rm resource.name

# Import resource
terraform import resource.name id
```

---

## 🔐 Security

### Check Security

```bash
# tfsec scan
tfsec .

# Checkov scan
checkov -d .

# TFLint
tflint --recursive

# Pre-commit
pre-commit run --all-files
```

### Secrets Management

```bash
# Scan for secrets
git secrets --scan

# Scan history
git secrets --scan-history

# Add pattern
git secrets --add 'pattern'
```

---

## 💰 Cost Management

### Check Costs

```bash
# AWS Cost Explorer
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost

# List budgets
aws budgets describe-budgets \
  --account-id $(aws sts get-caller-identity --query Account --output text)
```

---

## 📊 Monitoring

### CloudWatch

```bash
# List log groups
aws logs describe-log-groups

# Tail logs
aws logs tail /aws/controltower/CloudTrailLogs --follow

# Get metric statistics
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-02T00:00:00Z \
  --period 3600 \
  --statistics Average
```

### GuardDuty

```bash
# List detectors
aws guardduty list-detectors

# Get findings
aws guardduty list-findings \
  --detector-id DETECTOR_ID
```

---

## 🏗️ Account Management

### Organizations

```bash
# Describe organization
aws organizations describe-organization

# List accounts
aws organizations list-accounts

# List OUs
aws organizations list-organizational-units-for-parent \
  --parent-id ROOT_ID

# List policies
aws organizations list-policies \
  --filter SERVICE_CONTROL_POLICY
```

### Account Vending

```terraform
# Add new account
accounts = {
  new_account = {
    name        = "New Account"
    email       = "aws-new@example.com"
    ou_id       = "ou-xxxx-xxxxxxxx"
    environment = "dev"
    vpc_cidr    = "10.5.0.0/16"
    # ... configuration
  }
}
```

---

## 🌐 Networking

### VPC

```bash
# List VPCs
aws ec2 describe-vpcs

# List subnets
aws ec2 describe-subnets

# List route tables
aws ec2 describe-route-tables

# List security groups
aws ec2 describe-security-groups
```

### Transit Gateway

```bash
# List transit gateways
aws ec2 describe-transit-gateways

# List attachments
aws ec2 describe-transit-gateway-attachments

# List route tables
aws ec2 describe-transit-gateway-route-tables
```

---

## 📝 Git Workflow

```bash
# Create feature branch
git checkout -b feature/my-feature

# Make changes
git add .
git commit -m "Description"

# Push branch
git push origin feature/my-feature

# Create PR
gh pr create --title "Title" --body "Description"

# Merge PR
gh pr merge --squash
```

---

## 🔄 CI/CD

### GitHub Actions

```bash
# List workflows
gh workflow list

# Run workflow
gh workflow run terraform-ci.yml

# View runs
gh run list

# View specific run
gh run view RUN_ID

# View logs
gh run view RUN_ID --log
```

---

## 📦 Modules

### Using Modules

```terraform
module "example" {
  source = "./modules/example"
  
  # Variables
  name        = "my-resource"
  environment = "prod"
  
  tags = var.tags
}

# Access outputs
output "example_id" {
  value = module.example.id
}
```

---

## 🎯 Best Practices

✅ Always run `terraform plan` before `apply`  
✅ Use workspaces for multiple environments  
✅ Enable state locking  
✅ Use remote state storage  
✅ Tag all resources  
✅ Use modules for reusability  
✅ Version control everything  
✅ Run security scans  
✅ Test before deploying  
✅ Document changes  

---

## 🆘 Emergency Procedures

### Rollback

```bash
# Revert to previous state
terraform state pull > current.tfstate
terraform state push previous.tfstate
terraform apply
```

### Disaster Recovery

```bash
# Restore from backup
aws s3 cp s3://backup-bucket/terraform.tfstate.backup .
terraform state push terraform.tfstate.backup
terraform plan
```

---

## 📞 Support

- **Documentation:** [docs/INDEX.html](INDEX.html)
- **GitHub Issues:** [github.com/your-org/your-repo/issues](https://github.com/your-org/your-repo/issues)
- **AWS Support:** [console.aws.amazon.com/support](https://console.aws.amazon.com/support)

---

{: .fs-3 }
💡 **Tip:** Bookmark this page for quick access to common commands!

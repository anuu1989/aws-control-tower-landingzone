---
layout: default
title: Getting Started
nav_order: 2
has_children: true
permalink: /getting-started
---

# Getting Started
{: .no_toc }

Complete guide to getting started with AWS Control Tower Landing Zone deployment.
{: .fs-6 .fw-300 }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

## Overview

This guide will walk you through the complete process of deploying AWS Control Tower using this Terraform automation.

{: .important }
> **Prerequisites Required**: Ensure you have AWS Organizations enabled and appropriate permissions before starting.

---

## Prerequisites

### Required

- **AWS Organizations** enabled in management account
- **Terraform** >= 1.6.0
- **AWS CLI** >= 2.0
- **Management account access** with administrator permissions
- **Minimum 2 email addresses** (Log Archive and Audit accounts)

### Recommended Tools

```bash
# Install recommended tools
brew install jq tfsec terraform-docs make

# Or using apt (Linux)
apt-get install jq make
```

---

## Installation Steps

### Step 1: Clone Repository

```bash
git clone https://github.com/your-org/aws-control-tower-landingzone.git
cd aws-control-tower-landingzone
```

### Step 2: Setup Pre-Commit Hooks

{: .highlight }
Pre-commit hooks prevent common mistakes and enforce code quality.

```bash
# Install pre-commit hooks
./scripts/setup-pre-commit.sh

# Install git-secrets
./scripts/setup-git-secrets.sh
```

### Step 3: Deploy Backend Infrastructure

{: .note }
This step is only required on first deployment.

```bash
# Navigate to backend example
cd examples/terraform-backend

# Copy and customize variables
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars

# Deploy backend
terraform init
terraform apply

# Save backend configuration
terraform output -raw backend_config_hcl > ../../backend.hcl

# Return to root
cd ../..
```

### Step 4: Configure Variables

```bash
# Copy production variables template
cp terraform.tfvars.production terraform.tfvars

# Edit with your values
vim terraform.tfvars
```

**Required Variables:**

```hcl
# Project identification
environment  = "production"
project_name = "enterprise-control-tower"

# Control Tower setup
home_region      = "ap-southeast-2"
governed_regions = ["ap-southeast-2", "us-east-1"]

# Notifications
notification_emails = ["platform-team@example.com"]

# Organizational Units
organizational_units = {
  security = {
    name        = "Security"
    environment = "security"
    tags        = {}
  }
  # ... more OUs
}
```

### Step 5: Initialize Terraform

```bash
# Initialize with backend configuration
terraform init -backend-config=backend.hcl
```

### Step 6: Run Pre-Deployment Checks

```bash
# Run validation
make pre-deploy

# Or manually
./scripts/pre-deployment-check.sh
```

### Step 7: Review Plan

```bash
# Generate and review plan
make plan

# Or manually
terraform plan -out=tfplan
```

### Step 8: Deploy

{: .warning }
> **Deployment Time**: Control Tower deployment takes 60-90 minutes. Do not interrupt the process.

```bash
# Deploy using Make
make apply

# Or manually
terraform apply tfplan
```

### Step 9: Post-Deployment

```bash
# Run post-deployment checklist
./scripts/post-deployment.sh
```

---

## Verification

### Verify Control Tower

```bash
# Check organization
aws organizations describe-organization

# List OUs
aws organizations list-organizational-units-for-parent \
  --parent-id $(aws organizations list-roots --query 'Roots[0].Id' --output text)

# Check Control Tower status
aws controltower list-landing-zones
```

### Verify Security Services

```bash
# Check GuardDuty
aws guardduty list-detectors

# Check Security Hub
aws securityhub describe-hub

# Check Config
aws configservice describe-configuration-recorders
```

---

## Next Steps

1. **Configure AWS SSO/Identity Center**
   - Set up identity source
   - Create permission sets
   - Assign users to accounts

2. **Enable Additional Security Services**
   - Configure GuardDuty in all regions
   - Enable Security Hub standards
   - Set up AWS Config rules

3. **Set Up Monitoring**
   - Create CloudWatch dashboards
   - Configure SNS notifications
   - Set up cost budgets

4. **Create Additional Accounts**
   - Use account vending module
   - Configure account baselines
   - Test account provisioning

---

## Troubleshooting

### Common Issues

**Issue: Backend initialization fails**
```bash
# Solution: Ensure backend is deployed first
cd examples/terraform-backend
terraform apply
```

**Issue: Insufficient permissions**
```bash
# Solution: Verify you're using management account with admin access
aws sts get-caller-identity
```

**Issue: Email already in use**
```bash
# Solution: Use unique email addresses for each account
# Use email aliases: user+logarchive@example.com
```

---

## Additional Resources

- [Complete Implementation Guide](COMPLETE_IMPLEMENTATION_GUIDE.html)
- [Deployment Guide](DEPLOYMENT_GUIDE.html)
- [Architecture Overview](ARCHITECTURE.html)
- [Troubleshooting Guide](COMPLETE_IMPLEMENTATION_GUIDE.html#troubleshooting)

---

{: .fs-3 }
Need help? Check our [Support](index.html#support) section or open an issue on GitHub.

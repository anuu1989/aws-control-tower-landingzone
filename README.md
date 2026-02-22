# AWS Control Tower Landing Zone - Enterprise Grade

Enterprise-grade Terraform automation for deploying AWS Control Tower with comprehensive governance, security, and compliance controls.

## Features

- **Multi-Account Architecture**: Secure, scalable organizational structure
- **Account Vending Machine**: Automated account creation and bootstrapping
- **Comprehensive SCPs**: 35+ pre-configured service control policies
- **Regional Deployment**: Sydney-based with multi-region support
- **Security by Default**: GuardDuty, Security Hub, AWS Config, Network Firewall
- **Secrets Management**: AWS Secrets Manager integration for sensitive data
- **Cost Optimization**: AWS Budgets, cost anomaly detection, lifecycle policies
- **Drift Detection**: Automated infrastructure drift detection every 6 hours
- **Pre-Commit Hooks**: Automated validation, security scanning, and linting
- **Disaster Recovery**: Comprehensive DR runbook and automated state backups
- **Fully Modular**: Reusable modules for easy customization
- **Production Ready**: Validation, monitoring, and operational tooling included
- **Extensible**: Add unlimited OUs and accounts without code changes

## Quick Start

```bash
# 1. Setup pre-commit hooks (recommended)
./scripts/setup-pre-commit.sh
./scripts/setup-git-secrets.sh

# 2. Deploy backend module (FIRST TIME ONLY - Terraform 1.6+ required)
cd examples/terraform-backend
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init
terraform apply
# Save backend config
terraform output -raw backend_config_hcl > ../../backend.hcl
cd ../..

# 3. Initialize with backend (no DynamoDB needed!)
terraform init -backend-config=backend.hcl

# 4. Run pre-deployment checks
make pre-deploy

# 5. Review the plan
make plan

# 6. Deploy (60-90 minutes)
make apply

# 7. Setup automated state backups (optional)
crontab -e
# Add: 0 */6 * * * /path/to/scripts/backup-state-automated.sh backup-bucket-name
```

## Architecture

- **Home Region**: Sydney (ap-southeast-2)
- **Organizational Units**: Fully extensible (default: 6 OUs)
- **Governance**: 9 comprehensive SCPs with flexible assignment
- **Modular Design**: Reusable modules for easy customization
- **Enterprise Features**: Monitoring, notifications, compliance controls

## Prerequisites

### Required
- AWS Organizations enabled in management account
- Terraform >= 1.5.0
- AWS CLI >= 2.0
- Management account access with administrator permissions
- Minimum 2 email addresses (Log Archive and Audit accounts)

### Recommended
- jq (for scripts)
- tfsec (security scanning)
- terraform-docs (documentation)
- make (automation)

See [DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md) for detailed prerequisites.

## Project Structure

```
.
├── main.tf                          # Root module orchestration
├── variables.tf                     # Input variables with validation
├── outputs.tf                       # Output values
├── locals.tf                        # Local values and validation
├── versions.tf                      # Terraform and provider versions
├── backend.hcl.example              # Backend configuration example
├── terraform.tfvars.production      # Production configuration example
├── Makefile                         # Automation commands
├── backend/                         # Backend infrastructure ⭐ NEW
│   ├── main.tf                     # S3 + DynamoDB backend
│   ├── variables.tf                # Backend variables
│   ├── terraform.tfvars.example    # Backend config example
│   └── README.md                   # Backend documentation
├── modules/
│   ├── control-tower/              # Control Tower landing zone
│   ├── organizational-units/       # OU management
│   ├── scp-policies/               # SCP policy definitions
│   ├── scp-attachments/            # Policy-to-OU attachments
│   ├── security/                   # Security module
│   ├── logging/                    # Logging module
│   ├── networking/                 # Networking module
│   ├── zero-trust/                 # Zero Trust architecture
│   ├── cost-optimization/          # Cost monitoring and budgets ⭐ NEW
│   ├── secrets-manager/            # Secrets management ⭐ NEW
│   ├── terraform-backend/          # Terraform backend module
│   └── account-vending/            # Account vending machine ⭐ NEW
│       └── bootstrap/              # Account bootstrap modules
│           ├── vpc/                # VPC infrastructure
│           ├── security-groups/    # Security groups
│           ├── iam/                # IAM roles
│           ├── logging/            # CloudWatch logs
│           ├── security/           # Security services
│           └── s3/                 # S3 buckets
├── scripts/
│   ├── setup-backend.sh            # Backend setup script
│   ├── setup-pre-commit.sh         # Pre-commit hooks setup ⭐ NEW
│   ├── setup-git-secrets.sh        # Git secrets setup ⭐ NEW
│   ├── backup-state-automated.sh   # Automated state backups ⭐ NEW
│   ├── pre-deployment-check.sh     # Pre-deployment validation
│   ├── post-deployment.sh          # Post-deployment checklist
│   ├── run-opa-tests.sh            # OPA policy tests
│   ├── run-terraform-tests.sh      # Terraform tests
│   └── validate-all.sh             # Complete validation
├── .github/workflows/
│   ├── terraform-ci.yml            # Main CI/CD pipeline
│   └── drift-detection.yml         # Automated drift detection ⭐ NEW
├── docs/
│   ├── DEPLOYMENT_GUIDE.md         # Comprehensive deployment guide
│   ├── ARCHITECTURE.md             # Architecture documentation
│   ├── BACKEND.md                  # Backend configuration guide
│   ├── DISASTER_RECOVERY.md        # DR runbook ⭐ NEW
│   ├── ACCOUNT_VENDING.md          # Account vending guide ⭐ NEW
│   ├── ADDITIONAL_BEST_PRACTICES.md # Best practices catalog ⭐ NEW
│   ├── BEST_PRACTICES_IMPLEMENTATION_STATUS.md # Implementation status ⭐ NEW
│   ├── COMPLETE_IMPLEMENTATION_GUIDE.md # Complete guide
│   └── INDEX.md                    # Documentation index
└── examples/
    ├── basic/                      # 2 OU example
    ├── multi-region/               # Multi-region example
    └── four-ous/                   # 4 OU example
```

## Documentation

- [Deployment Guide](docs/DEPLOYMENT_GUIDE.md) - Step-by-step deployment instructions
- [Architecture](docs/ARCHITECTURE.md) - Detailed architecture documentation
- [Security](docs/SECURITY.md) - Security features and controls
- [Networking](docs/NETWORKING.md) - Network architecture and firewall configuration
- [SCP Policies](docs/SCP_POLICIES.md) - Service Control Policy documentation
- [Testing Guide](docs/TESTING.md) - Testing framework and best practices
- [Examples](examples/) - Example configurations

## Deployment

### Using Make (Recommended)

```bash
# Check prerequisites
make pre-deploy

# Initialize and validate
make init validate

# Plan deployment
make plan

# Deploy
make apply

# View outputs
make output
```

### Manual Deployment

```bash
# 1. Run pre-deployment checks
./scripts/pre-deployment-check.sh

# 2. Configure backend (edit versions.tf)
# 3. Copy and customize configuration
cp terraform.tfvars.production terraform.tfvars
vim terraform.tfvars

# 4. Initialize
terraform init

# 5. Plan
terraform plan -out=tfplan

# 6. Apply
terraform apply tfplan
```

See [DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md) for detailed instructions.

## Configuration

### Core Variables

```hcl
# Project identification
environment  = "production"
project_name = "enterprise-control-tower"

# Control Tower setup
home_region      = "ap-southeast-2"
governed_regions = ["ap-southeast-2", "ap-southeast-1", "us-east-1"]

# Notifications
notification_emails = ["platform-team@example.com"]
```

### Organizational Units

Define your OU structure:

```hcl
organizational_units = {
  security = {
    name        = "Security"
    environment = "security"
    tags        = { Purpose = "Security and Audit" }
  }
  development = {
    name        = "Development"
    environment = "dev"
    tags        = { CostCenter = "Engineering" }
  }
  production = {
    name        = "Production"
    environment = "prod"
    tags        = { Criticality = "High" }
  }
}
```

### Service Control Policies

Assign SCPs to each OU:

```hcl
ou_scp_policies = {
  security    = ["require_mfa"]
  development = ["require_mfa", "deny_public_s3", "restrict_instance_types"]
  production  = ["require_mfa"]
}
```

Keys must match `organizational_units` keys. Add unlimited OUs without code changes!

## Available SCPs

### Root-Level (All Accounts)
1. **deny_root_user** - Blocks all root user actions
2. **deny_leave_org** - Prevents accounts from leaving
3. **protect_cloudtrail** - Prevents CloudTrail tampering
4. **protect_security_services** - Protects GuardDuty, SecurityHub, Config
5. **restrict_regions** - Limits to approved regions
6. **require_encryption** - Enforces S3 and EBS encryption

### OU-Specific
7. **require_mfa** - Enforces MFA for API calls
8. **deny_public_s3** - Prevents public S3 buckets
9. **restrict_instance_types** - Limits EC2 instance types

## Operational Commands

```bash
# Validation
make validate              # Validate configuration
make lint                  # Run TFLint
make security-scan         # Run security scan (requires tfsec)
make cost-estimate         # Estimate costs (requires infracost)

# Testing
make test                  # Run basic tests
make test-all              # Run complete test suite
make test-unit             # Run Terratest unit tests
make test-opa              # Run OPA policy tests

# Deployment
make plan                  # Generate plan
make apply                 # Deploy infrastructure
make output                # Show outputs

# Maintenance
make check-drift           # Check for configuration drift
make refresh               # Refresh state
make backup-state          # Backup state file

# Cleanup
make destroy               # Destroy infrastructure
make clean                 # Clean local files
```

## Post-Deployment

After deployment completes:

1. **Configure AWS SSO/Identity Center**
   - Set up identity source
   - Create permission sets
   - Assign users to accounts

2. **Enable Security Services**
   - GuardDuty in all regions
   - Security Hub with CIS benchmark
   - AWS Config rules

3. **Set Up Account Factory**
   - Configure in Service Catalog
   - Define account baselines
   - Test account provisioning

4. **Configure Monitoring**
   - CloudWatch dashboards
   - SNS notifications
   - Cost budgets and alerts

See [scripts/post-deployment.sh](scripts/post-deployment.sh) for complete checklist.

## Testing

The project includes a comprehensive testing framework:

### Test Types

1. **Terraform Validation** - Syntax and configuration validation
2. **Unit Tests** - Terratest-based infrastructure tests (8 test suites)
3. **Policy Tests** - OPA policy validation (50+ rules, 30+ test cases)
4. **Security Scanning** - TFSec and Checkov security analysis
5. **Linting** - TFLint for best practices

### Running Tests

```bash
# Run all tests
make test-all

# Run specific test suites
make test-unit              # Terratest unit tests
make test-opa               # OPA policy tests
make lint                   # TFLint
make security-scan          # TFSec security scan

# Individual test scripts
./scripts/run-terraform-tests.sh
./scripts/run-opa-tests.sh
./scripts/validate-all.sh
```

### Test Coverage

- Control Tower deployment validation
- Organizational unit management
- SCP policy enforcement
- Security module (KMS, GuardDuty, Security Hub, Config)
- Logging module (CloudTrail, CloudWatch, S3)
- Networking module (Transit Gateway, Network Firewall)
- Variable validation
- Output verification

See [docs/TESTING.md](docs/TESTING.md) for detailed testing documentation.

### Prerequisites for Testing

```bash
# Required
terraform >= 1.5.0
go >= 1.21 (for Terratest)
opa >= 0.60.0 (for policy tests)

# Optional
tflint (linting)
tfsec (security scanning)
checkov (compliance scanning)
```

### CI/CD Integration

The project includes GitHub Actions workflow (`.github/workflows/terraform-ci.yml`) that runs:
- Terraform format check
- Terraform validation
- TFSec security scan
- OPA policy tests
- Terratest unit tests (on main branch)


## Monitoring and Notifications

The deployment includes:
- CloudWatch Log Group for Control Tower events
- SNS topic for notifications
- EventBridge rules for lifecycle events
- Email subscriptions for alerts

## Security Features

- Root user access blocked across all accounts
- MFA enforcement for API operations
- Regional restrictions (Sydney, Singapore, US-East-1)
- Mandatory encryption for S3 and EBS
- CloudTrail protection
- Security service protection (Config, GuardDuty, SecurityHub)
- Public access prevention
- Instance type restrictions (non-prod)

## Compliance

Supports compliance frameworks:
- SOC 2
- ISO 27001
- PCI DSS
- CIS AWS Foundations Benchmark
- GDPR (with additional controls)

## Troubleshooting

### Common Issues

**"Control Tower already exists"**
- Review existing setup
- Consider using `terraform import`

**"Insufficient permissions"**
- Verify IAM permissions
- Ensure running from management account

**"Service quota exceeded"**
- Request quota increase via AWS Support

See [DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md#troubleshooting) for detailed troubleshooting.

## Maintenance

### Adding New OUs
```bash
# Edit terraform.tfvars
# Add to organizational_units and ou_scp_policies
make plan
make apply
```

### Updating SCPs
```bash
# Edit modules/scp-policies/main.tf or terraform.tfvars
make plan
make apply
```

### Upgrading Landing Zone
```bash
# Update landing_zone_version in terraform.tfvars
make plan
make apply
```

## Examples

Three example configurations provided:

1. **basic/** - Simple 2 OU setup
2. **multi-region/** - 3 OUs with multiple regions  
3. **four-ous/** - 4 OUs demonstrating extensibility

## Best Practices Implementation

This project implements comprehensive best practices for AWS Control Tower deployments:

### ✅ Implemented

1. **Pre-Commit Hooks** - Automated validation, security scanning, and linting
   ```bash
   ./scripts/setup-pre-commit.sh
   ```

2. **Secrets Management** - AWS Secrets Manager integration for sensitive data
   ```terraform
   module "secrets_manager" {
     source = "./modules/secrets-manager"
     # ... configuration
   }
   ```

3. **Automated State Backups** - Scheduled backups with retention
   ```bash
   ./scripts/backup-state-automated.sh backup-bucket-name
   ```

4. **Drift Detection** - Automated infrastructure drift detection every 6 hours
   - GitHub workflow: `.github/workflows/drift-detection.yml`
   - Creates issues when drift detected
   - Sends Slack notifications

5. **Cost Optimization** - AWS Budgets, cost anomaly detection, lifecycle policies
   ```terraform
   module "cost_optimization" {
     source = "./modules/cost-optimization"
     # ... configuration
   }
   ```

6. **Account Vending Machine** - Automated account creation and bootstrapping
   ```terraform
   module "account_vending" {
     source = "./modules/account-vending"
     # ... configuration
   }
   ```

7. **Disaster Recovery** - Comprehensive DR runbook and procedures
   - See: `docs/DISASTER_RECOVERY.md`

8. **Git Secrets** - Prevent committing sensitive data
   ```bash
   ./scripts/setup-git-secrets.sh
   ```

### 📚 Documentation

- [Additional Best Practices](docs/ADDITIONAL_BEST_PRACTICES.md) - Complete catalog of 60+ best practices
- [Implementation Status](docs/BEST_PRACTICES_IMPLEMENTATION_STATUS.md) - Current implementation status (85% complete)
- [Account Vending Guide](docs/ACCOUNT_VENDING.md) - Account vending machine documentation
- [Disaster Recovery](docs/DISASTER_RECOVERY.md) - DR runbook and procedures

### 🔄 Automated Workflows

- **CI/CD Pipeline** - Validation, security scanning, testing on every PR
- **Drift Detection** - Runs every 6 hours, creates issues, sends notifications
- **State Backups** - Can be scheduled with cron for automated backups

### 📊 Monitoring

- CloudWatch dashboards for cost and security metrics
- AWS Budgets with multiple alert thresholds
- Cost anomaly detection
- Secret access monitoring
- Infrastructure drift alerts

See [BEST_PRACTICES_IMPLEMENTATION_STATUS.md](docs/BEST_PRACTICES_IMPLEMENTATION_STATUS.md) for complete details.

---

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run `make validate` and `make security-scan`
5. Submit a pull request

## License

[Your License Here]

## Support

For issues and questions:
- Review [DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md)
- Check [ARCHITECTURE.md](docs/ARCHITECTURE.md)
- Open an issue in the repository
- Contact AWS Support for Control Tower issues

## Acknowledgments

Built with:
- Terraform by HashiCorp
- AWS Control Tower
- AWS Organizations

---

**Note**: Control Tower deployment takes 60-90 minutes. Plan accordingly and ensure you have the necessary permissions and prerequisites before starting.

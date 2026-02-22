---
layout: default
title: Home
nav_order: 1
description: "Enterprise-grade Terraform automation for AWS Control Tower with comprehensive governance, security, and compliance controls"
permalink: /
---

# AWS Control Tower Landing Zone
{: .fs-9 }

Enterprise-grade Terraform automation for deploying AWS Control Tower with comprehensive governance, security, and compliance controls.
{: .fs-6 .fw-300 }

[Get Started](#quick-start){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 .mr-2 }
[View on GitHub](https://github.com/your-org/aws-control-tower-landingzone){: .btn .fs-5 .mb-4 .mb-md-0 }

---

## 🚀 Features

<div class="code-example" markdown="1">

### Multi-Account Architecture
Secure, scalable organizational structure with automated account vending

### 35+ Service Control Policies
Comprehensive governance controls for security and compliance

### Zero Trust Networking
Network Firewall with stateful inspection and deny-by-default rules

### Automated Operations
Drift detection, state backups, and account bootstrapping

### Cost Optimization
AWS Budgets, anomaly detection, and lifecycle policies

### Secrets Management
AWS Secrets Manager integration for sensitive data

### Comprehensive Testing
8 test suites with 50+ OPA policy rules

### Extensive Documentation
20+ guides covering all aspects of deployment and operations

</div>

---

## 📊 Project Status

| Component | Status | Completion |
|:----------|:------:|:----------:|
| Core Infrastructure | ✅ Complete | 100% |
| Security & Compliance | ✅ Complete | 100% |
| Networking | ✅ Complete | 100% |
| Account Vending | ✅ Complete | 100% |
| Cost Optimization | ✅ Complete | 100% |
| Secrets Management | ✅ Complete | 100% |
| Testing Framework | ✅ Complete | 100% |
| Documentation | ✅ Complete | 100% |
| Best Practices | ⏳ Partial | 85% |

**Overall Status:** ✅ Production Ready

---

## 🎯 Quick Start

### Prerequisites

{: .important }
> Ensure you have AWS Organizations enabled and Terraform 1.6+ installed before proceeding.

```bash
# Required
- AWS Organizations enabled
- Terraform >= 1.6.0
- AWS CLI >= 2.0
- Management account access

# Recommended
- jq, tfsec, terraform-docs, make
```

### Installation

```bash
# 1. Setup pre-commit hooks
./scripts/setup-pre-commit.sh
./scripts/setup-git-secrets.sh

# 2. Deploy backend (first time only)
cd examples/terraform-backend
terraform init && terraform apply
terraform output -raw backend_config_hcl > ../../backend.hcl
cd ../..

# 3. Initialize and deploy
terraform init -backend-config=backend.hcl
make plan
make apply
```

{: .note }
Control Tower deployment takes 60-90 minutes. Plan accordingly.

---

## 📚 Documentation

<div class="code-example" markdown="1">

### Getting Started
- [Complete Implementation Guide](COMPLETE_IMPLEMENTATION_GUIDE.html) - Comprehensive guide covering all aspects
- [Deployment Guide](DEPLOYMENT_GUIDE.html) - Step-by-step deployment instructions
- [Quick Start](../README.html#quick-start) - Get up and running quickly

### Architecture & Design
- [Architecture Overview](ARCHITECTURE.html) - System architecture and design decisions
- [Security](SECURITY.html) - Security features and controls
- [Networking](NETWORKING.html) - Network architecture and firewall configuration
- [Zero Trust](ZERO_TRUST.html) - Zero Trust architecture implementation

### Operations
- [Account Vending](ACCOUNT_VENDING.html) - Automated account creation and bootstrapping
- [Disaster Recovery](DISASTER_RECOVERY.html) - DR runbook and procedures
- [Best Practices](ADDITIONAL_BEST_PRACTICES.html) - Catalog of 60+ best practices
- [Testing Guide](TESTING.html) - Testing framework and best practices

</div>

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Management Account                        │
│  ┌────────────────────────────────────────────────────────┐ │
│  │              Control Tower Landing Zone                │ │
│  │  • GuardDuty  • Security Hub  • AWS Config            │ │
│  │  • CloudTrail • Network Firewall • Transit Gateway    │ │
│  └────────────────────────────────────────────────────────┘ │
└──────────────────────────┬───────────────────────────────────┘
                           │
        ┌──────────────────┴──────────────────┐
        │                                     │
┌───────▼────────┐                   ┌────────▼───────┐
│  Security OU   │                   │  Workload OUs  │
│                │                   │                │
│  • Log Archive │                   │  • Production  │
│  • Audit       │                   │  • Non-Prod    │
│  • Security    │                   │  • Development │
└────────────────┘                   └────────────────┘
```

---

## 🔒 Security Features

- **35+ Service Control Policies** - Comprehensive governance controls
- **GuardDuty** - Threat detection across all accounts
- **Security Hub** - CIS and AWS Foundational standards
- **AWS Config** - Configuration compliance tracking
- **Network Firewall** - Stateful packet inspection
- **KMS Encryption** - All data encrypted at rest
- **IAM Access Analyzer** - Resource access analysis
- **VPC Flow Logs** - Network traffic monitoring

---

## 💰 Cost Estimate

| Component | Monthly Cost | Notes |
|:----------|-------------:|:------|
| Control Tower | $0 | No charge |
| GuardDuty | $5-10 | Per account |
| Security Hub | $5-10 | Per account |
| AWS Config | $10-20 | Per account |
| Network Firewall | $350+ | Per AZ |
| Transit Gateway | $36+ | Per attachment |
| NAT Gateway | $32-96 | Per gateway |
| **Total (Single Account)** | **$450-550** | Approximate |

{: .highlight }
Cost optimization features can reduce costs by 20-30% in non-production environments.

---

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.html) for details.

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests: `make test-all`
5. Submit a pull request

---

## 📞 Support

For issues and questions:
- Review the [Documentation](INDEX.html)
- Check [Troubleshooting Guide](COMPLETE_IMPLEMENTATION_GUIDE.html#troubleshooting)
- Open an issue on [GitHub](https://github.com/your-org/aws-control-tower-landingzone/issues)
- Contact AWS Support for Control Tower issues

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE.html) file for details.

---

{: .fs-3 }
Built with ❤️ using Terraform, AWS Control Tower, and AWS Organizations

# Testing Quick Reference

Quick guide for running tests on the AWS Control Tower Landing Zone automation.

## Quick Start

```bash
# Run all tests
make test-all

# Run specific test suites
make test-unit              # Terratest unit tests
make test-opa               # OPA policy tests
make lint                   # TFLint
make security-scan          # TFSec security scan
```

## Test Structure

```
tests/
├── README.md                    # This file
├── fixtures/                    # Test data
│   ├── valid-plan.json         # Valid Terraform plan
│   └── invalid-plan.json       # Invalid plan (for testing violations)
└── terraform/                   # Terratest unit tests
    ├── go.mod                  # Go dependencies
    └── main_test.go            # Test suites
```

## Prerequisites

### Install Testing Tools

```bash
# OPA (Open Policy Agent)
brew install opa

# Go (for Terratest)
brew install go

# TFLint
brew install tflint

# TFSec
brew install tfsec

# Checkov (optional)
pip install checkov
```

### Verify Installation

```bash
opa version      # >= 0.60.0
go version       # >= 1.21
tflint --version
tfsec --version
```

## Running Tests

### 1. OPA Policy Tests

Test OPA policies against Terraform plans:

```bash
# Run OPA unit tests
opa test policies/opa/ -v

# Run via script
./scripts/run-opa-tests.sh

# Test against fixtures
opa eval --data policies/opa/terraform.rego \
  --input tests/fixtures/valid-plan.json \
  'data.terraform.controltower.deny'

# Expected: No violations for valid-plan.json
# Expected: Multiple violations for invalid-plan.json
```

### 2. Terratest Unit Tests

Run Go-based infrastructure tests:

```bash
# Run all tests
cd tests/terraform
go test -v -timeout 30m

# Run specific test
go test -v -run TestControlTowerDeployment

# Run via script
./scripts/run-terraform-tests.sh
```

### 3. Terraform Validation

```bash
# Format check
terraform fmt -check -recursive

# Validate
terraform init -backend=false
terraform validate
```

### 4. Linting

```bash
# TFLint
tflint --init
tflint --recursive

# Via Make
make lint
```

### 5. Security Scanning

```bash
# TFSec
tfsec . --soft-fail

# Checkov
checkov -d . --quiet --compact

# Via Make
make security-scan
```

### 6. Complete Validation

Run all validations in sequence:

```bash
./scripts/validate-all.sh
```

This runs:
1. Terraform format check
2. Terraform validation
3. TFLint (if installed)
4. TFSec (if installed)
5. Checkov (if installed)
6. OPA policy tests
7. Terraform plan generation

## Test Suites

### Terratest Tests (tests/terraform/main_test.go)

| Test | Description |
|------|-------------|
| TestControlTowerDeployment | Tests main Control Tower deployment |
| TestOrganizationalUnits | Tests OU module |
| TestSCPPolicies | Tests SCP policy module |
| TestSecurityModule | Tests security module (KMS, GuardDuty, etc.) |
| TestLoggingModule | Tests logging module (CloudTrail, S3) |
| TestNetworkingModule | Tests networking module (TGW, Firewall) |
| TestVariableValidation | Tests input variable validation |
| TestOutputs | Tests output values |

### OPA Policy Tests (policies/opa/terraform_test.rego)

30+ test cases covering:
- KMS encryption requirements
- S3 security (encryption, public access, versioning)
- EC2 security (IMDSv2, termination protection)
- RDS security (encryption, public access, backups, Multi-AZ)
- Network security (security groups, VPC flow logs)
- CloudTrail configuration
- GuardDuty enablement
- AWS Config recorder
- ElastiCache encryption
- Secrets Manager encryption

## Test Fixtures

### Valid Plan (tests/fixtures/valid-plan.json)

Contains compliant resources:
- S3 bucket with encryption and public access block
- CloudTrail with log validation and multi-region
- GuardDuty enabled
- Config recorder with all resources
- KMS key with rotation

### Invalid Plan (tests/fixtures/invalid-plan.json)

Contains non-compliant resources for testing violations:
- S3 bucket without encryption
- RDS instance publicly accessible
- EC2 instance without IMDSv2
- Security group allowing SSH from 0.0.0.0/0
- KMS key without rotation
- CloudTrail without log validation
- GuardDuty disabled
- ElastiCache without encryption
- Secrets Manager without KMS

## CI/CD Integration

GitHub Actions workflow runs on:
- Pull requests: validate, security-scan, opa-tests, plan
- Push to main: validate, security-scan, opa-tests, unit-tests, apply

See `.github/workflows/terraform-ci.yml`

## Troubleshooting

### OPA Tests Fail

```bash
# Check OPA version
opa version

# Run with verbose output
opa test policies/opa/ -v

# Test specific rule
opa test policies/opa/ -v -r test_s3_bucket_encryption_required
```

### Terratest Timeout

```bash
# Increase timeout
go test -v -timeout 60m

# Run specific test
go test -v -run TestSecurityModule -timeout 30m
```

### Go Module Issues

```bash
cd tests/terraform
go clean -modcache
go mod download
go mod tidy
```

### TFLint Errors

```bash
# Initialize TFLint
tflint --init

# Check configuration
cat .tflint.hcl

# Run with debug
tflint --loglevel=debug
```

## Best Practices

1. **Run tests before committing**
   ```bash
   make test-all
   ```

2. **Test incrementally during development**
   ```bash
   make validate  # Quick syntax check
   make test-opa  # Policy validation
   ```

3. **Use fixtures for policy testing**
   - Test against `valid-plan.json` (should pass)
   - Test against `invalid-plan.json` (should fail)

4. **Review test output**
   - OPA shows which policies failed
   - Terratest shows detailed error messages
   - TFSec shows security issues with remediation

5. **Keep tests updated**
   - Add tests for new features
   - Update fixtures when adding resources
   - Review and update policies regularly

## Additional Resources

- [Full Testing Guide](../docs/TESTING.md)
- [OPA Documentation](https://www.openpolicyagent.org/docs/latest/)
- [Terratest Documentation](https://terratest.gruntwork.io/)
- [TFSec Rules](https://aquasecurity.github.io/tfsec/)

## Support

For testing issues:
1. Check this guide
2. Review [docs/TESTING.md](../docs/TESTING.md)
3. Check test output and logs
4. Verify tool versions
5. Open an issue

---

**Quick Commands Summary**

```bash
# Complete test suite
make test-all

# Individual suites
make test-unit              # Terratest
make test-opa               # OPA policies
make lint                   # TFLint
make security-scan          # TFSec

# Scripts
./scripts/run-terraform-tests.sh
./scripts/run-opa-tests.sh
./scripts/validate-all.sh

# Manual
opa test policies/opa/ -v
cd tests/terraform && go test -v
terraform validate
tflint --recursive
tfsec .
```

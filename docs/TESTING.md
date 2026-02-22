# Testing Guide

Comprehensive testing framework for AWS Control Tower Landing Zone automation.

## Overview

This project includes multiple layers of testing:

1. **Terraform Validation** - Syntax and configuration validation
2. **Unit Tests** - Terratest-based infrastructure tests
3. **Policy Tests** - OPA (Open Policy Agent) policy validation
4. **Security Scanning** - TFSec and Checkov security analysis
5. **Integration Tests** - End-to-end deployment validation

## Prerequisites

### Required Tools

```bash
# Terraform
terraform --version  # >= 1.5.0

# Go (for Terratest)
go version  # >= 1.21

# OPA (Open Policy Agent)
opa version  # >= 0.60.0

# AWS CLI
aws --version  # >= 2.0
```

### Optional Tools

```bash
# TFLint - Terraform linting
brew install tflint

# TFSec - Security scanning
brew install tfsec

# Checkov - Security and compliance scanning
pip install checkov

# jq - JSON processing
brew install jq
```

## Installation

### Install OPA

```bash
# macOS
brew install opa

# Linux
curl -L -o opa https://openpolicyagent.org/downloads/latest/opa_linux_amd64
chmod +x opa
sudo mv opa /usr/local/bin/

# Verify installation
opa version
```

### Install Go (for Terratest)

```bash
# macOS
brew install go

# Linux
wget https://go.dev/dl/go1.21.0.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin

# Verify installation
go version
```

### Install Terratest Dependencies

```bash
cd tests/terraform
go mod download
go mod tidy
```

## Running Tests

### Quick Start - Run All Tests

```bash
# Run complete validation suite
make test-all

# Or use the validation script
./scripts/validate-all.sh
```

### Individual Test Suites

#### 1. Terraform Validation

```bash
# Format check
terraform fmt -check -recursive

# Validate configuration
terraform init -backend=false
terraform validate

# Using Make
make validate
```

#### 2. Unit Tests (Terratest)

```bash
# Run all unit tests
./scripts/run-terraform-tests.sh

# Run specific test
cd tests/terraform
go test -v -run TestControlTowerDeployment

# Run with timeout
go test -v -timeout 30m

# Using Make
make test-unit
```

#### 3. OPA Policy Tests

```bash
# Run OPA unit tests
./scripts/run-opa-tests.sh

# Run specific test
opa test policies/opa/ -v -r test_s3_bucket_encryption_required

# Validate against Terraform plan
terraform plan -out=tfplan
terraform show -json tfplan > tfplan.json
opa eval --data policies/opa/terraform.rego --input tfplan.json 'data.terraform.controltower.deny'

# Using Make
make test-opa
```

#### 4. Security Scanning

```bash
# TFSec scan
tfsec . --soft-fail

# Checkov scan
checkov -d . --quiet --compact

# Using Make
make security-scan
```

#### 5. Linting

```bash
# TFLint
tflint --init
tflint

# Using Make
make lint
```

## Test Structure

### Terratest Unit Tests

Located in `tests/terraform/main_test.go`:

```
TestControlTowerDeployment    - Tests main deployment
TestOrganizationalUnits       - Tests OU module
TestSCPPolicies              - Tests SCP module
TestSecurityModule           - Tests security module
TestLoggingModule            - Tests logging module
TestNetworkingModule         - Tests networking module
TestVariableValidation       - Tests input validation
TestOutputs                  - Tests output values
```

### OPA Policy Tests

Located in `policies/opa/`:

- `terraform.rego` - Policy definitions (50+ rules)
- `terraform_test.rego` - Test cases (30+ tests)

Policy categories:
- KMS Encryption
- S3 Security
- EC2 Security
- RDS Security
- Network Security
- IAM Security
- CloudTrail
- GuardDuty
- Security Hub
- AWS Config
- Tagging
- Load Balancers
- Lambda
- ElastiCache
- Secrets Manager

## Writing Tests

### Adding Terratest Tests

```go
func TestNewFeature(t *testing.T) {
    t.Parallel()

    terraformOptions := &terraform.Options{
        TerraformDir: "../../modules/my-module",
        Vars: map[string]interface{}{
            "variable_name": "value",
        },
    }

    defer terraform.Destroy(t, terraformOptions)
    
    terraform.InitAndApply(t, terraformOptions)
    
    // Assertions
    output := terraform.Output(t, terraformOptions, "output_name")
    assert.Equal(t, "expected_value", output)
}
```

### Adding OPA Policies

```rego
# Policy rule
deny[msg] {
    resource := resources_by_type("aws_resource_type")[_]
    not resource.values.required_property
    msg := sprintf("Resource '%s' must have required_property", [resource.address])
}

# Test case
test_resource_property_required {
    deny["Resource 'aws_resource_type.test' must have required_property"] with input as {
        "planned_values": {
            "root_module": {
                "resources": [
                    {
                        "address": "aws_resource_type.test",
                        "type": "aws_resource_type",
                        "values": {}
                    }
                ]
            }
        }
    }
}
```

## CI/CD Integration

### GitHub Actions

The project includes `.github/workflows/terraform-ci.yml`:

```yaml
- Runs on: push, pull_request
- Steps:
  1. Terraform format check
  2. Terraform validation
  3. TFSec security scan
  4. OPA policy tests
  5. Terratest unit tests (on main branch)
```

### Pre-commit Hooks

Create `.git/hooks/pre-commit`:

```bash
#!/bin/bash
set -e

echo "Running pre-commit checks..."

# Format check
terraform fmt -check -recursive || {
    echo "Run: terraform fmt -recursive"
    exit 1
}

# Validation
terraform validate

# OPA tests
./scripts/run-opa-tests.sh

echo "✓ Pre-commit checks passed"
```

Make it executable:
```bash
chmod +x .git/hooks/pre-commit
```

## Test Data

### Example Terraform Plan JSON

Create `tests/fixtures/valid-plan.json`:

```json
{
  "planned_values": {
    "root_module": {
      "resources": [
        {
          "address": "aws_s3_bucket.example",
          "type": "aws_s3_bucket",
          "values": {
            "bucket": "example-bucket",
            "tags": {
              "Environment": "production",
              "ManagedBy": "terraform",
              "Project": "control-tower"
            }
          }
        },
        {
          "address": "aws_s3_bucket_server_side_encryption_configuration.example",
          "type": "aws_s3_bucket_server_side_encryption_configuration",
          "values": {
            "bucket": "aws_s3_bucket.example"
          }
        }
      ]
    }
  }
}
```

Test against it:
```bash
opa eval --data policies/opa/terraform.rego --input tests/fixtures/valid-plan.json 'data.terraform.controltower.deny'
```

## Troubleshooting

### Common Issues

#### OPA Tests Fail

```bash
# Check OPA installation
opa version

# Run with verbose output
opa test policies/opa/ -v

# Check specific test
opa test policies/opa/ -v -r test_name
```

#### Terratest Timeout

```bash
# Increase timeout
go test -v -timeout 60m

# Run specific test
go test -v -run TestName -timeout 30m
```

#### Go Module Issues

```bash
cd tests/terraform
go mod tidy
go clean -modcache
go mod download
```

#### TFSec False Positives

Add exceptions in `.tfsec/config.yml`:

```yaml
exclude:
  - aws-s3-enable-bucket-logging
```

Or inline:
```hcl
resource "aws_s3_bucket" "example" {
  #tfsec:ignore:aws-s3-enable-bucket-logging
  bucket = "example"
}
```

## Best Practices

### Test Organization

1. **Unit tests** - Test individual modules in isolation
2. **Integration tests** - Test module interactions
3. **End-to-end tests** - Test complete deployment
4. **Policy tests** - Validate compliance and security

### Test Naming

- Use descriptive names: `TestSecurityModuleKMSEncryption`
- Follow pattern: `Test<Module><Feature>`
- OPA tests: `test_<resource>_<requirement>`

### Test Data

- Use realistic but non-sensitive data
- Create fixtures for common scenarios
- Document test data requirements

### Performance

- Use `t.Parallel()` for independent tests
- Set appropriate timeouts
- Clean up resources in `defer` statements

### Coverage

- Test happy paths and error cases
- Validate all critical security controls
- Test variable validation logic
- Verify output values

## Continuous Improvement

### Adding New Tests

When adding features:

1. Write Terratest unit test
2. Add OPA policy if security-related
3. Update test documentation
4. Run full test suite
5. Update CI/CD pipeline if needed

### Test Maintenance

- Review and update tests with code changes
- Remove obsolete tests
- Keep test data current
- Monitor test execution time

## Resources

- [Terratest Documentation](https://terratest.gruntwork.io/)
- [OPA Documentation](https://www.openpolicyagent.org/docs/latest/)
- [TFSec Rules](https://aquasecurity.github.io/tfsec/)
- [Checkov Policies](https://www.checkov.io/5.Policy%20Index/terraform.html)
- [Terraform Testing Best Practices](https://www.terraform.io/docs/language/modules/testing-experiment.html)

## Support

For testing issues:
1. Check this documentation
2. Review test output and logs
3. Verify tool versions
4. Check GitHub issues
5. Contact the team

---

**Note**: Always run tests before deploying to production. The test suite helps catch issues early and ensures compliance with security policies.

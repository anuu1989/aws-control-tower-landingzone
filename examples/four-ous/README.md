# Four OUs Example

This example demonstrates the extensibility of the Control Tower module with 4 organizational units:

1. **Development** - For active development work
2. **Testing** - For QA and testing
3. **Staging** - Pre-production environment
4. **Production** - Live production workloads

## Architecture

Each OU has different SCP policies based on its purpose:

- **Dev & Test**: Strictest controls (MFA, public S3 blocked, instance type restrictions)
- **Staging**: Moderate controls (MFA, public S3 blocked)
- **Production**: Minimal additional controls (MFA only)

All OUs inherit root-level policies (deny root user, protect CloudTrail, etc.)

## Usage

```bash
cd examples/four-ous
terraform init
terraform plan
terraform apply
```

## Adding More OUs

To add a 5th OU (e.g., "sandbox"):

```hcl
organizational_units = {
  # ... existing OUs ...
  sandbox = {
    name        = "Sandbox"
    environment = "sandbox"
    tags = {
      CostCenter = "Engineering"
      Purpose    = "Experimentation"
    }
  }
}

ou_scp_policies = {
  # ... existing policies ...
  sandbox = [
    "require_mfa",
    "restrict_instance_types"
  ]
}
```

No code changes needed - just configuration!

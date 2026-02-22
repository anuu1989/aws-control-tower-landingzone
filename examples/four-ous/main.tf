# ============================================================================
# Four OUs Example - Extensible Organizational Structure
# ============================================================================
# This example demonstrates the extensibility of the OU structure with:
# - Four organizational units (Development, Testing, Staging, Production)
# - Environment-specific tags and policies
# - Progressive security controls (strictest in dev, most permissive in prod)
# - Custom cost center and purpose tags
#
# This pattern is common for organizations with:
# - Separate development and testing environments
# - Pre-production staging environment
# - Production environment with minimal restrictions
#
# Usage:
#   terraform init
#   terraform plan
#   terraform apply
#
# Note: You can extend this to 5, 6, or more OUs by adding entries
# to the organizational_units and ou_scp_policies maps.
# ============================================================================

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-southeast-2"
}

# Example with 4 OUs demonstrating extensibility
module "control_tower" {
  source = "../../"

  # Required Variables
  environment  = "development"
  project_name = "ct-four-ous"

  # Control Tower Configuration
  home_region      = "ap-southeast-2"
  governed_regions = ["ap-southeast-2", "us-east-1"]

  # Define 4 organizational units with custom tags
  # This demonstrates the fully extensible OU structure
  organizational_units = {
    dev = {
      name        = "Development"
      environment = "dev"
      tags = {
        CostCenter = "Engineering"
        Purpose    = "Development"
      }
    }
    test = {
      name        = "Testing"
      environment = "test"
      tags = {
        CostCenter = "Engineering"
        Purpose    = "QA"
      }
    }
    staging = {
      name        = "Staging"
      environment = "staging"
      tags = {
        CostCenter = "Engineering"
        Purpose    = "Pre-Production"
      }
    }
    prod = {
      name        = "Production"
      environment = "prod"
      tags = {
        CostCenter = "Operations"
        Purpose    = "Production"
      }
    }
  }

  # Service Control Policies
  allowed_regions                = ["ap-southeast-2", "us-east-1"]
  allowed_instance_types_nonprod = ["t3.*", "t3a.*", "t4g.*"]

  # Root-level policies apply to all accounts
  root_scp_policies = [
    "deny_root_user",
    "deny_leave_org",
    "protect_cloudtrail",
    "protect_security_services",
    "restrict_regions",
    "require_encryption"
  ]

  # Define policies per OU - fully extensible
  # Progressive security: strictest in dev/test, most permissive in prod
  ou_scp_policies = {
    dev = [
      "require_mfa",
      "deny_public_s3",
      "restrict_instance_types"
    ]
    test = [
      "require_mfa",
      "deny_public_s3",
      "restrict_instance_types"
    ]
    staging = [
      "require_mfa",
      "deny_public_s3"
    ]
    prod = [
      "require_mfa"
    ]
  }

  # Disable expensive features for example
  enable_centralized_networking = false
  enable_macie                  = false

  # Notification emails (optional - add your emails here)
  security_notification_emails    = []
  operational_notification_emails = []
}

# ============================================================================
# Outputs
# ============================================================================

output "organization_id" {
  description = "AWS Organization ID"
  value       = module.control_tower.organization_id
}

output "ou_ids" {
  description = "Organizational unit IDs"
  value       = module.control_tower.organizational_units.ids
}

output "ou_details" {
  description = "Detailed OU information including policies"
  value       = module.control_tower.ou_details
}

output "scp_attachments" {
  description = "SCP attachment IDs"
  value       = module.control_tower.scp_attachments
}

output "root_scp_policies_attached" {
  description = "List of SCPs attached to root OU"
  value       = module.control_tower.root_scp_policies_attached
}

# ============================================================================
# Multi-Region Example - Control Tower with Multiple Regions
# ============================================================================
# This example demonstrates a multi-region Control Tower deployment with:
# - Three organizational units (NonProd, Prod, Sandbox)
# - Multiple governed regions (Sydney, Singapore, US East)
# - Custom SCP policy attachments
# - More permissive instance types for multi-region workloads
#
# Usage:
#   terraform init
#   terraform plan
#   terraform apply
#
# Note: Multi-region deployments increase complexity and cost.
# Ensure you have a business need for multiple regions.
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

module "control_tower" {
  source = "../../"

  # Required Variables
  environment  = "development"
  project_name = "ct-multi-region"

  # Control Tower Configuration
  home_region = "ap-southeast-2"
  governed_regions = [
    "ap-southeast-2", # Sydney - Home region
    "ap-southeast-1", # Singapore - Secondary region
    "us-east-1"       # Global services (required)
  ]

  # Organizational Units - 3 OUs for different environments
  organizational_units = {
    nonprod = {
      name        = "NonProd"
      environment = "non-prod"
      tags        = {}
    }
    prod = {
      name        = "Prod"
      environment = "prod"
      tags        = {}
    }
    sandbox = {
      name        = "Sandbox"
      environment = "sandbox"
      tags        = { Purpose = "Testing" }
    }
  }

  # Service Control Policies
  allowed_regions = [
    "ap-southeast-2",
    "ap-southeast-1",
    "us-east-1"
  ]

  # More permissive instance types for multi-region workloads
  allowed_instance_types_nonprod = ["t3.*", "t3a.*", "t4g.*", "m5.*"]

  # Customize root-level SCP attachments
  root_scp_policies = [
    "deny_root_user",
    "deny_leave_org",
    "protect_cloudtrail",
    "restrict_regions"
  ]

  # Customize OU-level SCP attachments
  ou_scp_policies = {
    nonprod = [
      "require_mfa",
      "restrict_instance_types"
    ]
    prod = [
      "require_mfa"
    ]
    sandbox = [
      "require_mfa",
      "restrict_instance_types",
      "deny_public_s3"
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

output "governed_regions" {
  description = "List of governed regions"
  value       = module.control_tower.governed_regions
}

output "ou_ids" {
  description = "Organizational unit IDs"
  value       = module.control_tower.organizational_units.ids
}

output "ou_details" {
  description = "Detailed OU information including policies"
  value       = module.control_tower.ou_details
}

output "scp_policies" {
  description = "SCP policy IDs and ARNs"
  value       = module.control_tower.scp_policies
}

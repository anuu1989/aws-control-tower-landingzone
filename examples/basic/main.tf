# ============================================================================
# Basic Example - Minimal Control Tower Deployment
# ============================================================================
# This example demonstrates a minimal Control Tower deployment with:
# - Two organizational units (NonProd and Prod)
# - Basic SCP policies
# - Sydney as home region
# - Minimal configuration for quick setup
#
# Usage:
#   terraform init
#   terraform plan
#   terraform apply
#
# Note: This example uses default values for most settings.
# For production deployments, see examples/four-ous/ or terraform.tfvars.production
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
  project_name = "ct-basic-example"

  # Control Tower Configuration
  home_region      = "ap-southeast-2"
  governed_regions = ["ap-southeast-2", "us-east-1"]

  # Organizational Units
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
  }

  # Service Control Policies
  allowed_regions                = ["ap-southeast-2", "us-east-1"]
  allowed_instance_types_nonprod = ["t3.*", "t3a.*", "t4g.*"]

  # Disable expensive features for basic example
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

output "organization_arn" {
  description = "AWS Organization ARN"
  value       = module.control_tower.organization_arn
}

output "root_id" {
  description = "Root organizational unit ID"
  value       = module.control_tower.root_id
}

output "ou_ids" {
  description = "Organizational unit IDs"
  value       = module.control_tower.organizational_units.ids
}

output "ou_arns" {
  description = "Organizational unit ARNs"
  value       = module.control_tower.organizational_units.arns
}

output "home_region" {
  description = "Control Tower home region"
  value       = module.control_tower.home_region
}

output "kms_key_id" {
  description = "KMS key ID for encryption"
  value       = module.control_tower.kms_key.id
}

output "sns_topics" {
  description = "SNS topic ARNs for notifications"
  value       = module.control_tower.sns_topics
}

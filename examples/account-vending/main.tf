# ============================================================================
# Account Vending Example - Automated Account Creation and Bootstrapping
# ============================================================================
# This example demonstrates how to use the account vending module to:
# - Create multiple AWS accounts
# - Bootstrap accounts with VPC, security groups, IAM roles
# - Enable security services
# - Configure logging and monitoring
#
# Usage:
#   terraform init
#   terraform plan
#   terraform apply
#
# Note: Account creation takes 5-10 minutes per account
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

# ============================================================================
# Data Sources
# ============================================================================

data "aws_caller_identity" "current" {}

data "aws_organizations_organization" "current" {}

# ============================================================================
# Control Tower Base Setup
# ============================================================================

module "control_tower" {
  source = "../../"

  # Required Variables
  environment  = "production"
  project_name = "ct-account-vending"

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

  # Disable expensive features for example
  enable_centralized_networking = false
  enable_macie                  = false

  # Notification emails
  security_notification_emails    = ["security@example.com"]
  operational_notification_emails = ["ops@example.com"]
}

# ============================================================================
# Account Vending - Create and Bootstrap Accounts
# ============================================================================

module "account_vending" {
  source = "../../modules/account-vending"

  # Management account configuration
  management_account_id = data.aws_caller_identity.current.account_id
  home_region           = "ap-southeast-2"

  # Enable bootstrapping
  enable_bootstrapping = true

  # Logging configuration
  central_log_bucket     = module.control_tower.logging.log_bucket.id
  kms_key_id             = module.control_tower.kms_key.id
  security_sns_topic_arn = module.control_tower.sns_topics.security.arn

  # Retention settings
  flow_logs_retention_days   = 30
  cloudwatch_retention_days  = 365
  s3_logs_retention_days     = 90
  s3_backups_retention_days  = 365

  # Create baseline S3 buckets
  create_baseline_buckets = true

  # ============================================================================
  # Define Accounts to Create
  # ============================================================================
  # This is fully extensible - add as many accounts as needed
  
  accounts = {
    # Development Account
    dev = {
      name        = "Development"
      email       = "aws-dev@example.com"  # Must be unique
      ou_id       = module.control_tower.organizational_units.ids["nonprod"]
      environment = "dev"
      role_name   = "OrganizationAccountAccessRole"

      # VPC Configuration
      vpc_cidr           = "10.1.0.0/16"
      availability_zones = ["ap-southeast-2a", "ap-southeast-2b"]
      enable_nat_gateway = true
      single_nat_gateway = true  # Cost savings for dev
      enable_vpn_gateway = false

      # Security Configuration
      allowed_ssh_cidrs   = ["10.0.0.0/8"]  # Internal only
      allowed_https_cidrs = ["0.0.0.0/0"]   # Public HTTPS

      # IAM Roles
      enable_admin_role     = true
      enable_readonly_role  = true
      enable_developer_role = true

      # Security Services
      enable_guardduty       = true
      enable_securityhub     = true
      enable_config          = true
      enable_access_analyzer = true

      # S3 Buckets
      create_data_bucket = true

      # Custom Tags
      tags = {
        CostCenter = "Engineering"
        Owner      = "DevTeam"
        Purpose    = "Development"
      }
    }

    # Testing Account
    test = {
      name        = "Testing"
      email       = "aws-test@example.com"
      ou_id       = module.control_tower.organizational_units.ids["nonprod"]
      environment = "test"
      role_name   = "OrganizationAccountAccessRole"

      vpc_cidr           = "10.2.0.0/16"
      availability_zones = ["ap-southeast-2a", "ap-southeast-2b"]
      enable_nat_gateway = true
      single_nat_gateway = true
      enable_vpn_gateway = false

      allowed_ssh_cidrs   = ["10.0.0.0/8"]
      allowed_https_cidrs = ["0.0.0.0/0"]

      enable_admin_role     = true
      enable_readonly_role  = true
      enable_developer_role = true

      enable_guardduty       = true
      enable_securityhub     = true
      enable_config          = true
      enable_access_analyzer = true

      create_data_bucket = true

      tags = {
        CostCenter = "Engineering"
        Owner      = "QATeam"
        Purpose    = "Testing"
      }
    }

    # Staging Account
    staging = {
      name        = "Staging"
      email       = "aws-staging@example.com"
      ou_id       = module.control_tower.organizational_units.ids["nonprod"]
      environment = "staging"
      role_name   = "OrganizationAccountAccessRole"

      vpc_cidr           = "10.3.0.0/16"
      availability_zones = ["ap-southeast-2a", "ap-southeast-2b"]
      enable_nat_gateway = true
      single_nat_gateway = false  # HA for staging
      enable_vpn_gateway = false

      allowed_ssh_cidrs   = ["10.0.0.0/8"]
      allowed_https_cidrs = ["0.0.0.0/0"]

      enable_admin_role     = true
      enable_readonly_role  = true
      enable_developer_role = false

      enable_guardduty       = true
      enable_securityhub     = true
      enable_config          = true
      enable_access_analyzer = true

      create_data_bucket = true

      tags = {
        CostCenter = "Engineering"
        Owner      = "OpsTeam"
        Purpose    = "Staging"
      }
    }

    # Production Account
    prod = {
      name        = "Production"
      email       = "aws-prod@example.com"
      ou_id       = module.control_tower.organizational_units.ids["prod"]
      environment = "prod"
      role_name   = "OrganizationAccountAccessRole"

      vpc_cidr           = "10.10.0.0/16"
      availability_zones = ["ap-southeast-2a", "ap-southeast-2b", "ap-southeast-2c"]
      enable_nat_gateway = true
      single_nat_gateway = false  # HA for production
      enable_vpn_gateway = true   # VPN for on-premises connectivity

      allowed_ssh_cidrs   = ["10.0.0.0/8"]
      allowed_https_cidrs = ["0.0.0.0/0"]

      enable_admin_role     = true
      enable_readonly_role  = true
      enable_developer_role = false  # No developer access in prod

      enable_guardduty       = true
      enable_securityhub     = true
      enable_config          = true
      enable_access_analyzer = true

      create_data_bucket = true

      tags = {
        CostCenter = "Operations"
        Owner      = "OpsTeam"
        Purpose    = "Production"
        Compliance = "SOC2"
      }
    }
  }

  # Default tags for all accounts
  tags = {
    ManagedBy  = "Terraform"
    Module     = "AccountVending"
    Repository = "aws-control-tower"
  }

  depends_on = [module.control_tower]
}

# ============================================================================
# Outputs
# ============================================================================

output "account_ids" {
  description = "Map of account keys to account IDs"
  value       = module.account_vending.account_ids
}

output "account_details" {
  description = "Detailed information about created accounts"
  value       = module.account_vending.account_details
  sensitive   = true
}

output "vpc_ids" {
  description = "Map of account keys to VPC IDs"
  value       = module.account_vending.vpc_ids
}

output "account_count" {
  description = "Total number of accounts created"
  value       = module.account_vending.account_count
}

output "next_steps" {
  description = "Post-deployment actions"
  value = <<-EOT
    Account Vending Complete!
    
    Created Accounts:
    ${join("\n    ", [for k, v in module.account_vending.account_ids : "- ${k}: ${v}"])}
    
    Next Steps:
    1. Verify accounts in AWS Organizations console
    2. Confirm email addresses for each account
    3. Test cross-account access with OrganizationAccountAccessRole
    4. Review VPC configurations in each account
    5. Verify security services are enabled
    6. Configure additional resources as needed
    
    Access Accounts:
    aws sts assume-role --role-arn arn:aws:iam::<ACCOUNT-ID>:role/OrganizationAccountAccessRole --role-session-name terraform
    
    View Account Details:
    terraform output account_details
  EOT
}

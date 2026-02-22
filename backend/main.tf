# ============================================================================
# Terraform Backend Infrastructure
# ============================================================================
# Uses the terraform-backend module to create S3 backend
# Terraform 1.6+ with native S3 state locking (no DynamoDB required)
# This should be deployed FIRST before the main Control Tower infrastructure
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
  region = var.region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Purpose     = "terraform-backend"
    }
  }
}

# ============================================================================
# Terraform Backend Module
# ============================================================================

module "terraform_backend" {
  source = "../modules/terraform-backend"

  name_prefix       = var.project_name
  state_bucket_name = var.state_bucket_name
  
  # Access control
  allowed_principals = var.allowed_account_ids
  
  # Retention
  state_retention_days = var.state_retention_days
  logs_retention_days  = var.logs_retention_days
  
  # Features
  enable_logging    = true
  enable_monitoring = true
  create_iam_policy = true
  
  # Monitoring
  alarm_sns_topic_arn         = var.alarm_sns_topic_arn
  state_bucket_size_threshold = var.state_bucket_size_threshold
  
  # KMS
  kms_deletion_window = var.kms_deletion_window
  
  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Purpose     = "terraform-backend"
  }
}

# ============================================================================
# Outputs
# ============================================================================

output "state_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  value       = module.terraform_backend.state_bucket_name
}

output "state_bucket_arn" {
  description = "ARN of the S3 bucket for Terraform state"
  value       = module.terraform_backend.state_bucket_arn
}

output "state_bucket_region" {
  description = "Region of the S3 bucket"
  value       = module.terraform_backend.state_bucket_region
}

output "kms_key_id" {
  description = "ID of the KMS key for state encryption"
  value       = module.terraform_backend.kms_key_id
}

output "kms_key_arn" {
  description = "ARN of the KMS key for state encryption"
  value       = module.terraform_backend.kms_key_arn
}

output "kms_key_alias" {
  description = "Alias of the KMS key"
  value       = module.terraform_backend.kms_key_alias
}

output "backend_policy_arn" {
  description = "ARN of the IAM policy for backend access"
  value       = module.terraform_backend.backend_policy_arn
}

output "logs_bucket_name" {
  description = "Name of the S3 bucket for access logs"
  value       = module.terraform_backend.logs_bucket_name
}

output "backend_config" {
  description = "Backend configuration for use in main Terraform code"
  value       = module.terraform_backend.backend_config
}

output "backend_config_hcl" {
  description = "Backend configuration in HCL format (save to backend.hcl)"
  value       = module.terraform_backend.backend_config_hcl
}

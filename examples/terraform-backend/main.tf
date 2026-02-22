# ============================================================================
# Example: Terraform Backend Module Usage
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
}

# ============================================================================
# Terraform Backend Module
# ============================================================================

module "terraform_backend" {
  source = "../../modules/terraform-backend"

  name_prefix       = var.project_name
  state_bucket_name = var.state_bucket_name
  
  # Access control
  allowed_principals = var.allowed_principals
  
  # Retention
  state_retention_days = var.state_retention_days
  logs_retention_days  = var.logs_retention_days
  
  # Features
  enable_logging    = var.enable_logging
  enable_monitoring = var.enable_monitoring
  create_iam_policy = var.create_iam_policy
  
  # Monitoring
  alarm_sns_topic_arn         = var.alarm_sns_topic_arn
  state_bucket_size_threshold = var.state_bucket_size_threshold
  
  # KMS
  kms_deletion_window = var.kms_deletion_window
  
  tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
    Project     = var.project_name
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

output "kms_key_id" {
  description = "ID of the KMS key for state encryption"
  value       = module.terraform_backend.kms_key_id
}

output "kms_key_arn" {
  description = "ARN of the KMS key for state encryption"
  value       = module.terraform_backend.kms_key_arn
}

output "backend_policy_arn" {
  description = "ARN of the IAM policy for backend access"
  value       = module.terraform_backend.backend_policy_arn
}

output "backend_config" {
  description = "Backend configuration for use in Terraform"
  value       = module.terraform_backend.backend_config
}

output "backend_config_hcl" {
  description = "Backend configuration in HCL format (save to backend.hcl)"
  value       = module.terraform_backend.backend_config_hcl
}

# ============================================================================
# Terraform Backend Variables
# ============================================================================

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "control-tower"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"

  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Environment must be development, staging, or production."
  }
}

variable "region" {
  description = "AWS region for backend resources"
  type        = string
  default     = "ap-southeast-2"
}

variable "state_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.state_bucket_name))
    error_message = "Bucket name must be lowercase alphanumeric with hyphens."
  }
}

# Note: DynamoDB table not needed with Terraform 1.6+
# Native S3 state locking is used instead

variable "allowed_account_ids" {
  description = "List of AWS account IDs allowed to access the state bucket"
  type        = list(string)
  default     = []
}

variable "kms_deletion_window" {
  description = "KMS key deletion window in days"
  type        = number
  default     = 30

  validation {
    condition     = var.kms_deletion_window >= 7 && var.kms_deletion_window <= 30
    error_message = "KMS deletion window must be between 7 and 30 days."
  }
}

variable "state_retention_days" {
  description = "Number of days to retain old state versions"
  type        = number
  default     = 90
}

variable "logs_retention_days" {
  description = "Number of days to retain access logs"
  type        = number
  default     = 365
}

variable "state_bucket_size_threshold" {
  description = "Threshold in bytes for state bucket size alarm"
  type        = number
  default     = 10737418240 # 10 GB
}

variable "alarm_sns_topic_arn" {
  description = "SNS topic ARN for CloudWatch alarms (optional)"
  type        = string
  default     = ""
}

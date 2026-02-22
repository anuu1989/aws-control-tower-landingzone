# ============================================================================
# Security Bootstrap Module - Variables
# ============================================================================
# Variables for configuring security services in bootstrapped accounts
# ============================================================================

# ----------------------------------------------------------------------------
# Account Information
# ----------------------------------------------------------------------------

variable "account_id" {
  description = "AWS Account ID being bootstrapped"
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.account_id))
    error_message = "Account ID must be a 12-digit number."
  }
}

variable "account_name" {
  description = "Name of the AWS account"
  type        = string

  validation {
    condition     = length(var.account_name) > 0 && length(var.account_name) <= 64
    error_message = "Account name must be between 1 and 64 characters."
  }
}

variable "environment" {
  description = "Environment name (dev, test, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "test", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, test, staging, prod."
  }
}

# ----------------------------------------------------------------------------
# Security Services Configuration
# ----------------------------------------------------------------------------

variable "enable_guardduty" {
  description = "Enable Amazon GuardDuty for threat detection"
  type        = bool
  default     = true
}

variable "enable_securityhub" {
  description = "Enable AWS Security Hub for security posture management"
  type        = bool
  default     = true
}

variable "enable_config" {
  description = "Enable AWS Config for resource configuration tracking"
  type        = bool
  default     = true
}

variable "enable_access_analyzer" {
  description = "Enable IAM Access Analyzer for resource access analysis"
  type        = bool
  default     = true
}

# ----------------------------------------------------------------------------
# Encryption Configuration
# ----------------------------------------------------------------------------

variable "kms_key_id" {
  description = "KMS key ID for encryption (optional, uses AWS managed keys if not provided)"
  type        = string
  default     = null
}

# ----------------------------------------------------------------------------
# Notifications
# ----------------------------------------------------------------------------

variable "sns_topic_arn" {
  description = "SNS topic ARN for security notifications (optional)"
  type        = string
  default     = null

  validation {
    condition     = var.sns_topic_arn == null || can(regex("^arn:aws:sns:", var.sns_topic_arn))
    error_message = "SNS topic ARN must be a valid ARN starting with 'arn:aws:sns:'."
  }
}

# ----------------------------------------------------------------------------
# AWS Config Configuration
# ----------------------------------------------------------------------------

variable "config_bucket_name" {
  description = "S3 bucket name for AWS Config delivery (required if enable_config is true)"
  type        = string
  default     = ""

  validation {
    condition     = var.config_bucket_name == "" || can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.config_bucket_name))
    error_message = "Config bucket name must be a valid S3 bucket name (lowercase, alphanumeric, hyphens)."
  }
}

# ----------------------------------------------------------------------------
# Tags
# ----------------------------------------------------------------------------

variable "tags" {
  description = "Tags to apply to all security resources"
  type        = map(string)
  default     = {}
}

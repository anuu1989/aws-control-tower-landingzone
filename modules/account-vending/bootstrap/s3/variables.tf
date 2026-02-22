# ============================================================================
# S3 Bootstrap Module - Variables
# ============================================================================
# Variables for configuring baseline S3 buckets in bootstrapped accounts
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
  description = "Name of the AWS account (used in bucket naming)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.account_name))
    error_message = "Account name must contain only lowercase letters, numbers, and hyphens."
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
# Bucket Creation Flags
# ----------------------------------------------------------------------------

variable "create_logs_bucket" {
  description = "Create S3 bucket for logs storage"
  type        = bool
  default     = true
}

variable "create_backups_bucket" {
  description = "Create S3 bucket for backups storage"
  type        = bool
  default     = true
}

variable "create_data_bucket" {
  description = "Create S3 bucket for application data storage"
  type        = bool
  default     = false
}

# ----------------------------------------------------------------------------
# Encryption Configuration
# ----------------------------------------------------------------------------

variable "kms_key_id" {
  description = "KMS key ID for bucket encryption (optional, uses AES256 if not provided)"
  type        = string
  default     = null
}

# ----------------------------------------------------------------------------
# Lifecycle Configuration
# ----------------------------------------------------------------------------

variable "logs_retention_days" {
  description = "Number of days to retain logs before deletion"
  type        = number
  default     = 365

  validation {
    condition     = var.logs_retention_days >= 1 && var.logs_retention_days <= 3650
    error_message = "Logs retention must be between 1 and 3650 days (10 years)."
  }
}

variable "backups_retention_days" {
  description = "Number of days to retain backups before deletion"
  type        = number
  default     = 730

  validation {
    condition     = var.backups_retention_days >= 1 && var.backups_retention_days <= 3650
    error_message = "Backups retention must be between 1 and 3650 days (10 years)."
  }
}

# ----------------------------------------------------------------------------
# Tags
# ----------------------------------------------------------------------------

variable "tags" {
  description = "Tags to apply to all S3 buckets"
  type        = map(string)
  default     = {}
}

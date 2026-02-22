# ============================================================================
# Terraform Backend Module Variables
# ============================================================================

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.name_prefix))
    error_message = "Name prefix must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "state_bucket_name" {
  description = "Name of the S3 bucket for Terraform state (must be globally unique)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.state_bucket_name)) && length(var.state_bucket_name) >= 3 && length(var.state_bucket_name) <= 63
    error_message = "Bucket name must be 3-63 characters, lowercase alphanumeric with hyphens, and cannot start or end with a hyphen."
  }
}

variable "allowed_principals" {
  description = "List of AWS principals (ARNs) allowed to access the state bucket"
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

  validation {
    condition     = var.state_retention_days >= 1
    error_message = "State retention days must be at least 1."
  }
}

variable "logs_retention_days" {
  description = "Number of days to retain access logs"
  type        = number
  default     = 365

  validation {
    condition     = var.logs_retention_days >= 1
    error_message = "Logs retention days must be at least 1."
  }
}

variable "state_bucket_size_threshold" {
  description = "Threshold in bytes for state bucket size alarm"
  type        = number
  default     = 10737418240 # 10 GB
}

variable "enable_logging" {
  description = "Enable S3 access logging"
  type        = bool
  default     = true
}

variable "enable_monitoring" {
  description = "Enable CloudWatch monitoring and alarms"
  type        = bool
  default     = true
}

variable "create_iam_policy" {
  description = "Create IAM policy for backend access"
  type        = bool
  default     = true
}

variable "alarm_sns_topic_arn" {
  description = "SNS topic ARN for CloudWatch alarms (optional)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

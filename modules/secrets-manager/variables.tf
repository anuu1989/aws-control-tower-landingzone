# ============================================================================
# Secrets Manager Module - Variables
# ============================================================================

# ----------------------------------------------------------------------------
# General Configuration
# ----------------------------------------------------------------------------

variable "name_prefix" {
  description = "Prefix for secret names"
  type        = string
  default     = "control-tower"
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.name_prefix))
    error_message = "Name prefix must contain only alphanumeric characters, hyphens, and underscores."
  }
}

variable "kms_key_id" {
  description = "KMS key ID for encrypting secrets (optional, uses AWS managed key if not provided)"
  type        = string
  default     = null
}

variable "recovery_window_days" {
  description = "Number of days to retain deleted secrets before permanent deletion"
  type        = number
  default     = 30
  
  validation {
    condition     = var.recovery_window_days >= 7 && var.recovery_window_days <= 30
    error_message = "Recovery window must be between 7 and 30 days."
  }
}

# ----------------------------------------------------------------------------
# Notification Emails
# ----------------------------------------------------------------------------

variable "security_notification_emails" {
  description = "List of email addresses for security notifications"
  type        = list(string)
  default     = []
  
  validation {
    condition = alltrue([
      for email in var.security_notification_emails :
      can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", email))
    ])
    error_message = "All email addresses must be valid."
  }
}

variable "operational_notification_emails" {
  description = "List of email addresses for operational notifications"
  type        = list(string)
  default     = []
  
  validation {
    condition = alltrue([
      for email in var.operational_notification_emails :
      can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", email))
    ])
    error_message = "All email addresses must be valid."
  }
}

variable "compliance_notification_emails" {
  description = "List of email addresses for compliance notifications"
  type        = list(string)
  default     = []
  
  validation {
    condition = alltrue([
      for email in var.compliance_notification_emails :
      can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", email))
    ])
    error_message = "All email addresses must be valid."
  }
}

# ----------------------------------------------------------------------------
# API Keys Secret
# ----------------------------------------------------------------------------

variable "create_api_keys_secret" {
  description = "Create secret for API keys"
  type        = bool
  default     = false
}

variable "api_keys" {
  description = "Map of API keys for external integrations"
  type        = map(string)
  default     = {}
  sensitive   = true
}

# ----------------------------------------------------------------------------
# Database Credentials Secret
# ----------------------------------------------------------------------------

variable "create_database_secret" {
  description = "Create secret for database credentials"
  type        = bool
  default     = false
}

variable "database_username" {
  description = "Database username"
  type        = string
  default     = ""
  sensitive   = true
}

variable "database_password" {
  description = "Database password"
  type        = string
  default     = ""
  sensitive   = true
}

variable "database_engine" {
  description = "Database engine (mysql, postgres, etc.)"
  type        = string
  default     = "postgres"
}

variable "database_host" {
  description = "Database host"
  type        = string
  default     = ""
}

variable "database_port" {
  description = "Database port"
  type        = number
  default     = 5432
}

variable "database_name" {
  description = "Database name"
  type        = string
  default     = ""
}

# ----------------------------------------------------------------------------
# Webhook URLs Secret
# ----------------------------------------------------------------------------

variable "create_webhook_secret" {
  description = "Create secret for webhook URLs"
  type        = bool
  default     = false
}

variable "slack_webhook_url" {
  description = "Slack webhook URL"
  type        = string
  default     = ""
  sensitive   = true
}

variable "teams_webhook_url" {
  description = "Microsoft Teams webhook URL"
  type        = string
  default     = ""
  sensitive   = true
}

# ----------------------------------------------------------------------------
# Monitoring
# ----------------------------------------------------------------------------

variable "secret_access_threshold" {
  description = "Threshold for secret access alarm (accesses per 5 minutes)"
  type        = number
  default     = 100
}

variable "alarm_sns_topic_arn" {
  description = "SNS topic ARN for secret access alarms"
  type        = string
  default     = null
}

# ----------------------------------------------------------------------------
# Tags
# ----------------------------------------------------------------------------

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

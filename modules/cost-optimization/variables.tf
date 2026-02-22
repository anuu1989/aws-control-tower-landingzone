# ============================================================================
# Cost Optimization Module - Input Variables
# ============================================================================

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "monthly_budget_limit" {
  description = "Monthly budget limit in USD"
  type        = number
  default     = 5000

  validation {
    condition     = var.monthly_budget_limit > 0
    error_message = "Monthly budget limit must be greater than 0."
  }
}

variable "budget_services" {
  description = "List of AWS services to include in budget (empty = all services)"
  type        = list(string)
  default     = []
}

variable "notification_emails" {
  description = "List of email addresses for budget notifications"
  type        = list(string)

  validation {
    condition = alltrue([
      for email in var.notification_emails :
      can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", email))
    ])
    error_message = "All notification emails must be valid email addresses."
  }
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for notifications"
  type        = string
}

variable "anomaly_alert_frequency" {
  description = "Frequency of anomaly alerts (DAILY, IMMEDIATE, WEEKLY)"
  type        = string
  default     = "DAILY"

  validation {
    condition     = contains(["DAILY", "IMMEDIATE", "WEEKLY"], var.anomaly_alert_frequency)
    error_message = "Anomaly alert frequency must be DAILY, IMMEDIATE, or WEEKLY."
  }
}

variable "anomaly_threshold" {
  description = "Dollar amount threshold for cost anomaly alerts"
  type        = number
  default     = 100

  validation {
    condition     = var.anomaly_threshold > 0
    error_message = "Anomaly threshold must be greater than 0."
  }
}

variable "production_account_ids" {
  description = "List of production AWS account IDs for cost categorization"
  type        = list(string)
  default     = []
}

variable "nonprod_account_ids" {
  description = "List of non-production AWS account IDs for cost categorization"
  type        = list(string)
  default     = []
}

variable "enable_quarterly_budget" {
  description = "Enable quarterly budget tracking"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

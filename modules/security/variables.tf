variable "account_id" {
  description = "AWS Account ID"
  type        = string
}

variable "region" {
  description = "AWS Region"
  type        = string
}

variable "kms_alias" {
  description = "Alias for the KMS key"
  type        = string
  default     = "control-tower"
}

variable "kms_deletion_window" {
  description = "KMS key deletion window in days"
  type        = number
  default     = 30
}

variable "kms_multi_region" {
  description = "Enable multi-region KMS key"
  type        = bool
  default     = false
}

variable "guardduty_finding_frequency" {
  description = "GuardDuty finding publishing frequency"
  type        = string
  default     = "FIFTEEN_MINUTES"

  validation {
    condition     = contains(["FIFTEEN_MINUTES", "ONE_HOUR", "SIX_HOURS"], var.guardduty_finding_frequency)
    error_message = "Must be FIFTEEN_MINUTES, ONE_HOUR, or SIX_HOURS."
  }
}

variable "enable_pci_dss" {
  description = "Enable PCI DSS compliance standard in Security Hub"
  type        = bool
  default     = false
}

variable "config_recorder_name" {
  description = "Name of the AWS Config recorder"
  type        = string
  default     = "control-tower-config-recorder"
}

variable "config_delivery_channel_name" {
  description = "Name of the AWS Config delivery channel"
  type        = string
  default     = "control-tower-config-delivery"
}

variable "config_delivery_frequency" {
  description = "AWS Config snapshot delivery frequency"
  type        = string
  default     = "TwentyFour_Hours"

  validation {
    condition = contains([
      "One_Hour",
      "Three_Hours",
      "Six_Hours",
      "Twelve_Hours",
      "TwentyFour_Hours"
    ], var.config_delivery_frequency)
    error_message = "Must be a valid Config delivery frequency."
  }
}

variable "log_bucket_name" {
  description = "Name of the S3 bucket for logs"
  type        = string
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for notifications"
  type        = string
}

variable "access_analyzer_name" {
  description = "Name of the Access Analyzer"
  type        = string
  default     = "control-tower-analyzer"
}

variable "enable_macie" {
  description = "Enable Amazon Macie for data discovery"
  type        = bool
  default     = false
}

variable "macie_finding_frequency" {
  description = "Macie finding publishing frequency"
  type        = string
  default     = "FIFTEEN_MINUTES"

  validation {
    condition     = contains(["FIFTEEN_MINUTES", "ONE_HOUR", "SIX_HOURS"], var.macie_finding_frequency)
    error_message = "Must be FIFTEEN_MINUTES, ONE_HOUR, or SIX_HOURS."
  }
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

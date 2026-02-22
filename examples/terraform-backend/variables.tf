# ============================================================================
# Example Variables
# ============================================================================

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "control-tower"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "region" {
  description = "AWS region for backend resources"
  type        = string
  default     = "ap-southeast-2"
}

variable "state_bucket_name" {
  description = "Name of the S3 bucket for Terraform state (must be globally unique)"
  type        = string
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

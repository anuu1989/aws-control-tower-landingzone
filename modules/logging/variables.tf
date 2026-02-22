variable "log_bucket_name" {
  description = "Name of the S3 bucket for centralized logging"
  type        = string
}

variable "cloudtrail_name" {
  description = "Name of the CloudTrail"
  type        = string
}

variable "kms_key_id" {
  description = "KMS key ID for encryption"
  type        = string
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for alarms"
  type        = string
}

variable "log_retention_days" {
  description = "Number of days to retain logs before deletion"
  type        = number
  default     = 2555 # 7 years
}

variable "log_transition_days" {
  description = "Number of days before transitioning to Glacier"
  type        = number
  default     = 90
}

variable "log_deep_archive_days" {
  description = "Number of days before transitioning to Deep Archive"
  type        = number
  default     = 365
}

variable "cloudwatch_retention_days" {
  description = "CloudWatch Logs retention in days"
  type        = number
  default     = 365
}

variable "unauthorized_api_threshold" {
  description = "Threshold for unauthorized API calls alarm"
  type        = number
  default     = 5
}

variable "iam_changes_threshold" {
  description = "Threshold for IAM policy changes alarm"
  type        = number
  default     = 1
}

variable "signin_failures_threshold" {
  description = "Threshold for console sign-in failures alarm"
  type        = number
  default     = 3
}

variable "vpc_changes_threshold" {
  description = "Threshold for VPC changes alarm"
  type        = number
  default     = 1
}

variable "security_group_changes_threshold" {
  description = "Threshold for security group changes alarm"
  type        = number
  default     = 5
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

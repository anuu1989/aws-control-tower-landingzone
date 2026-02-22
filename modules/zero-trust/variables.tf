# ============================================================================
# Zero Trust Module Variables
# ============================================================================

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for Zero Trust VPC"
  type        = string
  default     = "10.100.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

variable "kms_key_id" {
  description = "KMS key ID for encryption"
  type        = string
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for notifications"
  type        = string
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 90
}

variable "session_logs_bucket" {
  description = "S3 bucket for Session Manager logs"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

# ============================================================================
# VPC Endpoints Configuration
# ============================================================================

variable "interface_endpoints" {
  description = "List of AWS services for interface endpoints"
  type        = list(string)
  default = [
    "ec2",
    "ec2messages",
    "ssm",
    "ssmmessages",
    "kms",
    "logs",
    "sts",
    "secretsmanager",
    "ecr.api",
    "ecr.dkr",
    "elasticloadbalancing",
    "autoscaling",
    "ecs",
    "ecs-agent",
    "ecs-telemetry"
  ]
}

# ============================================================================
# Zero Trust Features
# ============================================================================

variable "enable_verified_access" {
  description = "Enable AWS Verified Access"
  type        = bool
  default     = true
}

variable "enable_privatelink" {
  description = "Enable AWS PrivateLink"
  type        = bool
  default     = true
}

variable "enable_ram_sharing" {
  description = "Enable AWS Resource Access Manager sharing"
  type        = bool
  default     = true
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection for load balancers"
  type        = bool
  default     = true
}

variable "enable_waf" {
  description = "Enable AWS WAF"
  type        = bool
  default     = true
}

# ============================================================================
# Security Thresholds
# ============================================================================

variable "unauthorized_calls_threshold" {
  description = "Threshold for unauthorized API calls alarm"
  type        = number
  default     = 5
}

variable "waf_rate_limit" {
  description = "WAF rate limit (requests per 5 minutes)"
  type        = number
  default     = 2000
}

variable "blocked_countries" {
  description = "List of country codes to block in WAF"
  type        = list(string)
  default     = []
}

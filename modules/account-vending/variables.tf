# ============================================================================
# Account Vending Module - Input Variables
# ============================================================================

# ============================================================================
# Account Configuration
# ============================================================================

variable "accounts" {
  description = "Map of AWS accounts to create and bootstrap"
  type = map(object({
    name        = string           # Account name
    email       = string           # Unique email for account
    ou_id       = string           # OU ID where account will be created
    environment = string           # Environment (prod, nonprod, dev, etc.)
    role_name   = string           # IAM role name for cross-account access
    
    # VPC Configuration
    vpc_cidr           = string       # VPC CIDR block
    availability_zones = list(string) # AZs for subnets
    enable_nat_gateway = bool         # Enable NAT Gateway
    single_nat_gateway = bool         # Use single NAT Gateway (cost savings)
    enable_vpn_gateway = bool         # Enable VPN Gateway
    
    # Security Configuration
    allowed_ssh_cidrs   = list(string) # CIDRs allowed for SSH
    allowed_https_cidrs = list(string) # CIDRs allowed for HTTPS
    
    # IAM Roles
    enable_admin_role     = bool # Enable admin role
    enable_readonly_role  = bool # Enable read-only role
    enable_developer_role = bool # Enable developer role
    
    # Security Services
    enable_guardduty       = bool # Enable GuardDuty
    enable_securityhub     = bool # Enable Security Hub
    enable_config          = bool # Enable AWS Config
    enable_access_analyzer = bool # Enable Access Analyzer
    
    # S3 Buckets
    create_data_bucket = bool # Create data bucket
    
    # Custom Tags
    tags = map(string)
  }))
  
  default = {}
  
  validation {
    condition = alltrue([
      for k, v in var.accounts :
      can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", v.email))
    ])
    error_message = "All account emails must be valid email addresses."
  }
  
  validation {
    condition = alltrue([
      for k, v in var.accounts :
      can(cidrhost(v.vpc_cidr, 0))
    ])
    error_message = "All VPC CIDRs must be valid CIDR blocks."
  }
}

variable "enable_bootstrapping" {
  description = "Enable automatic account bootstrapping"
  type        = bool
  default     = true
}

variable "close_on_deletion" {
  description = "Close account when Terraform resource is destroyed (requires manual confirmation)"
  type        = bool
  default     = false
}

# ============================================================================
# Regional Configuration
# ============================================================================

variable "home_region" {
  description = "Primary AWS region"
  type        = string
  default     = "ap-southeast-2"
}

# ============================================================================
# Management Account Configuration
# ============================================================================

variable "management_account_id" {
  description = "Management account ID for cross-account access"
  type        = string
}

# ============================================================================
# Logging Configuration
# ============================================================================

variable "central_log_bucket" {
  description = "Central S3 bucket for logs"
  type        = string
}

variable "flow_logs_retention_days" {
  description = "VPC Flow Logs retention in days"
  type        = number
  default     = 30
}

variable "cloudwatch_retention_days" {
  description = "CloudWatch Logs retention in days"
  type        = number
  default     = 365
}

variable "s3_logs_retention_days" {
  description = "S3 logs retention in days"
  type        = number
  default     = 90
}

variable "s3_backups_retention_days" {
  description = "S3 backups retention in days"
  type        = number
  default     = 365
}

# ============================================================================
# Security Configuration
# ============================================================================

variable "kms_key_id" {
  description = "KMS key ID for encryption"
  type        = string
}

variable "security_sns_topic_arn" {
  description = "SNS topic ARN for security notifications"
  type        = string
}

variable "config_bucket_name" {
  description = "S3 bucket name for AWS Config delivery"
  type        = string
  default     = ""
}

# ============================================================================
# S3 Bucket Configuration
# ============================================================================

variable "create_baseline_buckets" {
  description = "Create baseline S3 buckets in accounts"
  type        = bool
  default     = true
}

# ============================================================================
# Tags
# ============================================================================

variable "tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
  default     = {}
}

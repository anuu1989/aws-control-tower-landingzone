# ============================================================================
# Input Variables - Configuration Parameters for Control Tower Deployment
# ============================================================================
#
# Purpose:
#   This file defines all input variables for the Control Tower landing zone
#   deployment. Variables are organized by functional area and include
#   comprehensive validation rules to catch configuration errors early.
#
# Variable Categories:
#   1. Core Configuration: Project name, environment, tags
#   2. Control Tower: Regions, landing zone version
#   3. Organizational Units: Extensible OU structure
#   4. Service Control Policies: Policy selection and configuration
#   5. Monitoring & Notifications: Email addresses, retention periods
#   6. Security & Compliance: KMS, GuardDuty, Security Hub, Config, Macie
#   7. Networking: Transit Gateway, Network Firewall, DNS Firewall
#
# Validation Strategy:
#   - Format validation: Regex patterns for emails, regions, names
#   - Range validation: Min/max values for numbers
#   - Enum validation: Allowed values for specific settings
#   - Logical validation: Cross-variable consistency checks
#
# Best Practices:
#   - All variables have descriptions explaining their purpose
#   - Sensible defaults provided where appropriate
#   - Validation rules prevent common configuration mistakes
#   - Comments explain the impact of changing values
#
# Usage:
#   1. Copy terraform.tfvars.example to terraform.tfvars
#   2. Customize values for your environment
#   3. Review validation rules before deployment
#   4. Use terraform.tfvars.production for production deployments
#
# ============================================================================

# ============================================================================
# Core Configuration Variables
# ============================================================================
# These variables define the fundamental identity and classification of
# the deployment. They're used for resource naming, tagging, and organizing
# resources across the AWS organization.

variable "environment" {
  description = "Environment name (e.g., production, staging, development)"
  type        = string

  # Validation: Ensure environment follows naming conventions
  # Accepted values: production, staging, development (or short forms)
  # This prevents typos and ensures consistency across deployments
  validation {
    condition     = can(regex("^(production|staging|development|prod|stg|dev)$", var.environment))
    error_message = "Environment must be one of: production, staging, development, prod, stg, dev."
  }
}

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string

  # Validation: Ensure project name is DNS-compatible
  # - Only lowercase letters, numbers, and hyphens
  # - Used in S3 bucket names, which have strict naming requirements
  # - Prevents deployment failures due to invalid resource names
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "repository_url" {
  description = "Git repository URL for tracking infrastructure code"
  type        = string
  default     = ""

  # Optional: Used for traceability and documentation
  # Helps teams identify where infrastructure code is maintained
  # Added to resource tags for audit and compliance
}

variable "default_tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
  default     = {}

  # These tags are merged with common_tags in locals.tf
  # Use for organization-specific tags like:
  # - CostCenter: "Engineering"
  # - Owner: "Platform Team"
  # - Compliance: "SOC2"
}

# ============================================================================
# Control Tower Configuration
# ============================================================================
# These variables configure AWS Control Tower landing zone deployment.
# Control Tower provides automated multi-account governance, guardrails,
# and centralized logging for AWS Organizations.
#
# Key Concepts:
# - Home Region: Primary region for Control Tower (cannot be changed after deployment)
# - Governed Regions: Regions where Control Tower enforces guardrails
# - Landing Zone Version: Control Tower version (determines available features)
#
# Important Notes:
# - Home region cannot be changed after initial deployment
# - us-east-1 must be included for global services (IAM, CloudFront, Route 53)
# - Adding/removing governed regions requires landing zone update

variable "home_region" {
  description = "Home region for Control Tower"
  type        = string
  default     = "ap-southeast-2" # Sydney

  # Validation: Ensure valid AWS region format
  # Format: <geo>-<direction>-<number> (e.g., ap-southeast-2)
  # This is the PRIMARY region for Control Tower and cannot be changed
  # after initial deployment without recreating the landing zone
  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]{1}$", var.home_region))
    error_message = "Home region must be a valid AWS region format (e.g., ap-southeast-2)."
  }
}

variable "governed_regions" {
  description = "List of regions governed by Control Tower"
  type        = list(string)
  default = [
    "ap-southeast-2", # Sydney - Home region
    "us-east-1"       # Required for global services (IAM, CloudFront, Route 53)
  ]

  # Validation: Ensure us-east-1 is included
  # us-east-1 is REQUIRED for global AWS services that only operate in this region
  # Without it, some guardrails and controls won't function properly
  validation {
    condition     = length(var.governed_regions) > 0 && contains(var.governed_regions, "us-east-1")
    error_message = "Governed regions must include us-east-1 for global services."
  }
}

variable "landing_zone_version" {
  description = "Control Tower landing zone version"
  type        = string
  default     = "3.3"

  # Validation: Ensure version format is X.Y
  # Control Tower versions determine available features and guardrails
  # Check AWS documentation for latest version and features
  # Upgrading requires landing zone update operation
  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+$", var.landing_zone_version))
    error_message = "Landing zone version must be in format X.Y (e.g., 3.3)."
  }
}

# ============================================================================
# Organizational Units Configuration
# ============================================================================
# Defines the organizational unit (OU) structure for the AWS Organization.
# OUs are logical groupings of AWS accounts that share common policies,
# governance requirements, and operational characteristics.
#
# Design Philosophy:
# - Fully extensible: Support 2 to N organizational units
# - Environment-based: Separate prod from non-prod workloads
# - Policy-driven: OUs serve as attachment points for SCPs
# - Flexible: Each OU can have custom tags and metadata
#
# Common OU Patterns:
# - By Environment: Prod, NonProd, Dev, Staging
# - By Function: Security, Infrastructure, Workloads, Sandbox
# - By Business Unit: Finance, Engineering, Marketing
# - Hybrid: Combination of above (e.g., Prod-Finance, NonProd-Engineering)
#
# Best Practices:
# - Start with 2-4 OUs, expand as needed
# - Use consistent naming conventions
# - Document OU purpose and policies
# - Plan OU structure before account creation

variable "organizational_units" {
  description = "Map of organizational units to create"
  type = map(object({
    name        = string      # Display name for the OU (e.g., "Production")
    environment = string      # Environment classification (e.g., "prod", "non-prod")
    tags        = map(string) # Additional custom tags for the OU
  }))

  # Default: Two-OU structure (Production and Non-Production)
  # This is a common starting point for most organizations
  # Expand by adding more entries to this map
  default = {
    nonprod = {
      name        = "NonProd"
      environment = "non-prod"
      tags        = {}
    }
    prod = {
      name        = "Prod"
      environment = "prod"
      tags        = {}
    }
  }

  # Validation: Ensure at least one OU is defined
  # An organization without OUs would have all accounts in root,
  # which is not recommended for governance and security
  validation {
    condition     = length(var.organizational_units) > 0
    error_message = "At least one organizational unit must be defined."
  }
}

# ============================================================================
# Service Control Policies Configuration
# ============================================================================
# Service Control Policies (SCPs) are organization-level policies that set
# maximum available permissions for accounts. They act as guardrails to
# prevent unauthorized actions, even if IAM policies would allow them.
#
# SCP Hierarchy:
# - Root SCPs: Apply to ALL accounts (cannot be bypassed)
# - OU SCPs: Apply only to accounts in specific OUs
# - Effective Permissions: Intersection of SCP + IAM policies
#
# Available Policy Categories (35+ policies):
# - Core Security: Root user, MFA, regions, organization protection
# - Logging & Monitoring: CloudTrail, Config, security services
# - Encryption: At-rest and in-transit encryption requirements
# - S3 Security: Public access, SSL, encryption
# - EC2 Security: Instance types, IMDSv2, public AMIs
# - Network Security: VPC, security groups, network controls
# - IAM Security: User creation, password policies
# - KMS Security: Key deletion protection
# - Database Security: RDS public access, backups, encryption
# - Additional Services: ELB logging, tagging requirements
#
# Best Practices:
# - Start with core security policies on root
# - Add environment-specific policies to OUs
# - Test policies in non-prod before applying to prod
# - Document policy exceptions and justifications
# - Review and update policies regularly

variable "allowed_regions" {
  description = "List of allowed AWS regions for SCP"
  type        = list(string)
  default = [
    "ap-southeast-2", # Sydney - Primary region
    "us-east-1"       # Global services (IAM, CloudFront, Route 53)
  ]

  # Validation: Ensure at least one region is specified
  # Restricting regions helps with:
  # - Data residency compliance
  # - Cost control (prevent accidental resources in expensive regions)
  # - Security (reduce attack surface)
  # - Operational simplicity (fewer regions to monitor)
  validation {
    condition     = length(var.allowed_regions) > 0
    error_message = "At least one allowed region must be specified."
  }
}

variable "allowed_instance_types_nonprod" {
  description = "Allowed EC2 instance types for non-prod environments"
  type        = list(string)
  default     = ["t3.*", "t3a.*", "t4g.*"] # Cost-effective instance families

  # Validation: Ensure at least one instance type pattern
  # Restricting instance types in non-prod helps with:
  # - Cost control (prevent expensive instances in dev/test)
  # - Right-sizing (encourage appropriate instance selection)
  # - Consistency (standardize on specific instance families)
  #
  # Patterns support wildcards:
  # - "t3.*" matches all t3 instances (t3.micro, t3.small, t3.medium, etc.)
  # - "t3.micro" matches only t3.micro
  validation {
    condition     = length(var.allowed_instance_types_nonprod) > 0
    error_message = "At least one instance type pattern must be specified."
  }
}

variable "enabled_scp_policies" {
  description = "List of SCP policies to enable"
  type        = list(string)

  # Default: Comprehensive set of 24 policies covering major security areas
  # This is a balanced set suitable for most organizations
  # Add or remove policies based on your security requirements
  #
  # Policy Selection Guidelines:
  # - Core Security: Always enable (deny_root_user, require_mfa, etc.)
  # - Encryption: Enable for compliance requirements
  # - Service-Specific: Enable based on services used
  # - Cost Control: Enable instance type restrictions for non-prod
  default = [
    # Core Security (4 policies)
    "deny_root_user",   # Prevent root account usage
    "require_mfa",      # Require MFA for console access
    "restrict_regions", # Limit operations to allowed regions
    "deny_leave_org",   # Prevent accounts from leaving organization

    # Logging and Monitoring (2 policies)
    "protect_cloudtrail",        # Prevent CloudTrail deletion/modification
    "protect_security_services", # Protect GuardDuty, Security Hub, Config

    # Encryption (6 policies)
    "require_encryption",           # Require encryption for various services
    "deny_unencrypted_rds",         # Require RDS encryption
    "deny_unencrypted_snapshots",   # Require snapshot encryption
    "require_kms_encryption",       # Require KMS for encryption
    "deny_unencrypted_secrets",     # Require Secrets Manager encryption
    "deny_unencrypted_elasticache", # Require ElastiCache encryption

    # S3 Security (4 policies)
    "deny_public_s3",        # Prevent public S3 buckets
    "deny_s3_public_access", # Block S3 public access settings
    "require_s3_ssl",        # Require SSL for S3 access

    # EC2 Security (4 policies)
    "restrict_instance_types", # Limit instance types (non-prod)
    "require_imdsv2",          # Require IMDSv2 for EC2 metadata
    "deny_public_ami",         # Prevent public AMI sharing

    # Network Security (3 policies)
    "deny_default_vpc", # Prevent default VPC usage

    # IAM Security (3 policies)
    "deny_iam_user_creation",      # Prevent IAM user creation (use SSO)
    "require_iam_password_policy", # Enforce strong password policy

    # KMS Security (1 policy)
    "deny_kms_key_deletion", # Prevent accidental KMS key deletion

    # Database Security (4 policies)
    "deny_public_rds",    # Prevent publicly accessible RDS
    "require_rds_backup", # Require RDS automated backups

    # Additional Services (4 policies)
    "require_elb_logging", # Require ELB access logging
    "require_tagging"      # Require specific tags on resources
  ]
}

variable "root_scp_policies" {
  description = "SCPs to attach to root OU (applies to all accounts)"
  type        = list(string)

  # Default: Critical policies that should apply organization-wide
  # These are non-negotiable security controls that protect the entire organization
  #
  # Root policies cannot be bypassed by any account, making them ideal for:
  # - Fundamental security controls
  # - Compliance requirements
  # - Data protection mandates
  # - Operational safety nets
  default = [
    "deny_root_user",            # Never allow root account usage
    "deny_leave_org",            # Prevent accounts from leaving organization
    "protect_cloudtrail",        # Protect audit logging
    "protect_security_services", # Protect security tooling
    "restrict_regions",          # Enforce data residency
    "require_encryption"         # Enforce encryption at rest
  ]
}

variable "ou_scp_policies" {
  description = "Map of OU keys to their SCP policies. Keys must match organizational_units keys."
  type        = map(list(string))

  # Default: Environment-specific policies
  # - NonProd: Stricter controls for cost and security
  # - Prod: Minimal additional controls (rely on root policies)
  #
  # Design Philosophy:
  # - Root policies provide baseline security for all accounts
  # - OU policies add environment-specific controls
  # - Production gets fewer restrictions (trusted environment)
  # - Non-production gets more restrictions (cost control, experimentation limits)
  #
  # Customization:
  # - Add more OUs as needed (must match organizational_units keys)
  # - Adjust policies based on environment requirements
  # - Consider separate OUs for sandbox, development, staging
  default = {
    nonprod = [
      "require_mfa",            # Require MFA for console access
      "deny_public_s3",         # Prevent public S3 buckets
      "restrict_instance_types" # Limit to cost-effective instances
    ]
    prod = [
      "require_mfa" # Require MFA for console access
    ]
  }
}

# ============================================================================
# Monitoring and Notifications Configuration
# ============================================================================
# Configures the monitoring, alerting, and notification system for the
# Control Tower environment. This includes email notifications, log retention,
# and CloudWatch alarm thresholds.
#
# Two-Tier Notification System:
# - Security Notifications: Critical security events (GuardDuty, Security Hub)
# - Operational Notifications: Routine operational events (CloudWatch, EventBridge)
#
# Log Retention Strategy:
# - CloudWatch Logs: Real-time analysis (365 days default)
# - S3 Standard: Frequent access (0-90 days)
# - S3 Glacier: Infrequent access (90-365 days)
# - S3 Deep Archive: Long-term retention (365-2555 days / 7 years)
#
# Compliance Considerations:
# - SOC 2: Requires 1+ year log retention
# - PCI DSS: Requires 1+ year log retention
# - HIPAA: Requires 6+ year log retention
# - Default: 7 years (2555 days) for comprehensive compliance

variable "security_notification_emails" {
  description = "List of email addresses for security notifications (high priority)"
  type        = list(string)
  default     = []

  # Validation: Ensure all emails are valid format
  # Security notifications include:
  # - GuardDuty findings (threats, anomalies)
  # - Security Hub alerts (compliance violations)
  # - Unauthorized API calls
  # - IAM policy changes
  # - Root account usage
  #
  # Best Practices:
  # - Use distribution lists (security@company.com)
  # - Include SOC/security team members
  # - Set up 24/7 monitoring for critical alerts
  # - Configure email filtering to prevent alert fatigue
  validation {
    condition = alltrue([
      for email in var.security_notification_emails :
      can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", email))
    ])
    error_message = "All notification emails must be valid email addresses."
  }
}

variable "operational_notification_emails" {
  description = "List of email addresses for operational notifications (normal priority)"
  type        = list(string)
  default     = []

  # Validation: Ensure all emails are valid format
  # Operational notifications include:
  # - Control Tower events (account creation, OU changes)
  # - Network bandwidth alerts
  # - Config compliance changes
  # - Routine CloudWatch alarms
  #
  # Best Practices:
  # - Use distribution lists (ops@company.com)
  # - Include DevOps/platform team members
  # - Review during business hours
  # - Set up ticketing system integration
  validation {
    condition = alltrue([
      for email in var.operational_notification_emails :
      can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", email))
    ])
    error_message = "All notification emails must be valid email addresses."
  }
}

variable "log_retention_days" {
  description = "S3 log retention period in days"
  type        = number
  default     = 2555 # 7 years (2555 days)

  # Validation: Minimum 365 days for compliance
  # Log retention requirements by compliance framework:
  # - SOC 2: 1 year minimum
  # - PCI DSS: 1 year minimum (3 months online, 9 months offline)
  # - HIPAA: 6 years minimum
  # - GDPR: Varies by data type and purpose
  # - ISO 27001: 1 year minimum
  #
  # Default: 7 years provides comprehensive coverage for most frameworks
  # Adjust based on your specific compliance requirements
  validation {
    condition     = var.log_retention_days >= 365
    error_message = "Log retention must be at least 365 days for compliance."
  }
}

variable "log_transition_days" {
  description = "Days before transitioning logs to Glacier"
  type        = number
  default     = 90

  # S3 Lifecycle: Standard → Glacier transition
  # - Days 0-90: S3 Standard (frequent access for recent investigations)
  # - Days 90+: Glacier (infrequent access, 50% cost reduction)
  #
  # Considerations:
  # - Glacier retrieval takes 3-5 hours (Expedited: 1-5 minutes, extra cost)
  # - Balance between cost savings and access speed
  # - Adjust based on investigation patterns
}

variable "log_deep_archive_days" {
  description = "Days before transitioning logs to Deep Archive"
  type        = number
  default     = 365

  # S3 Lifecycle: Glacier → Deep Archive transition
  # - Days 90-365: Glacier (infrequent access)
  # - Days 365+: Deep Archive (long-term retention, 75% cost reduction vs Standard)
  #
  # Considerations:
  # - Deep Archive retrieval takes 12-48 hours
  # - Lowest cost storage option
  # - Suitable for compliance-only retention
  # - Rarely accessed after 1 year
}

variable "cloudwatch_retention_days" {
  description = "CloudWatch Logs retention period in days"
  type        = number
  default     = 365

  # Validation: Must be a valid CloudWatch retention period
  # CloudWatch Logs retention options (in days):
  # 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653
  #
  # CloudWatch vs S3 Logs:
  # - CloudWatch: Real-time analysis, queries, insights, alarms
  # - S3: Long-term storage, compliance, cost-effective
  #
  # Strategy:
  # - Keep recent logs in CloudWatch for active monitoring (365 days)
  # - Archive all logs to S3 for long-term retention (7 years)
  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.cloudwatch_retention_days)
    error_message = "CloudWatch retention days must be a valid retention period."
  }
}

# ============================================================================
# CloudWatch Alarm Thresholds
# ============================================================================
# Configures sensitivity of CloudWatch alarms for security and operational
# events. Lower thresholds = more sensitive (more alerts, fewer missed events).
# Higher thresholds = less sensitive (fewer alerts, potential missed events).
#
# Tuning Guidelines:
# - Start with defaults
# - Monitor alert frequency for 2-4 weeks
# - Adjust thresholds to reduce false positives
# - Balance between alert fatigue and security visibility
#
# Threshold Types:
# - Count: Number of events in evaluation period
# - Rate: Events per time period
# - Percentage: Ratio of events to total

variable "unauthorized_api_threshold" {
  description = "Threshold for unauthorized API calls alarm"
  type        = number
  default     = 5

  # Triggers when: 5+ unauthorized API calls in 5 minutes
  # Indicates: Potential credential compromise, misconfigured IAM, or attack
  # Action: Immediate investigation required
  #
  # Tuning:
  # - Lower (1-3): Very sensitive, may alert on legitimate errors
  # - Default (5): Balanced, catches most attacks
  # - Higher (10+): Less sensitive, may miss slow attacks
}

variable "iam_changes_threshold" {
  description = "Threshold for IAM policy changes alarm"
  type        = number
  default     = 1

  # Triggers when: 1+ IAM policy change in 5 minutes
  # Indicates: IAM policy modification (could be legitimate or malicious)
  # Action: Review change for authorization and correctness
  #
  # Why threshold = 1:
  # - IAM changes are infrequent in well-managed environments
  # - Every change should be reviewed for security
  # - Helps detect unauthorized privilege escalation
}

variable "signin_failures_threshold" {
  description = "Threshold for console sign-in failures alarm"
  type        = number
  default     = 3

  # Triggers when: 3+ failed console sign-ins in 5 minutes
  # Indicates: Potential brute force attack or credential stuffing
  # Action: Investigate source IP, user, and lock account if needed
  #
  # Tuning:
  # - Lower (1-2): Very sensitive, may alert on typos
  # - Default (3): Balanced, catches most attacks
  # - Higher (5+): Less sensitive, may miss slow attacks
}

variable "vpc_changes_threshold" {
  description = "Threshold for VPC changes alarm"
  type        = number
  default     = 1

  # Triggers when: 1+ VPC configuration change in 5 minutes
  # Indicates: Network configuration modification
  # Action: Review change for authorization and security impact
  #
  # Why threshold = 1:
  # - VPC changes are infrequent and high-impact
  # - Every change should be reviewed for security
  # - Helps detect unauthorized network exposure
}

variable "security_group_changes_threshold" {
  description = "Threshold for security group changes alarm"
  type        = number
  default     = 5

  # Triggers when: 5+ security group changes in 5 minutes
  # Indicates: Firewall rule modifications
  # Action: Review changes for unauthorized access
  #
  # Tuning:
  # - Lower (1-3): Very sensitive, may alert on legitimate changes
  # - Default (5): Balanced, catches bulk modifications
  # - Higher (10+): Less sensitive, may miss gradual exposure
}

# ============================================================================
# Security and Compliance Configuration
# ============================================================================
# Configures AWS security services for threat detection, compliance monitoring,
# and data protection. These services provide defense-in-depth security and
# continuous compliance validation.
#
# Services Configured:
# - KMS: Customer-managed encryption keys
# - GuardDuty: Intelligent threat detection
# - Security Hub: Centralized security and compliance
# - AWS Config: Resource configuration tracking
# - Macie: Sensitive data discovery (optional)
#
# Compliance Standards Supported:
# - AWS Foundational Security Best Practices (always enabled)
# - CIS AWS Foundations Benchmark (always enabled)
# - PCI DSS (optional, for payment card data)
#
# Cost Considerations:
# - GuardDuty: ~$5-10/account/month
# - Security Hub: ~$0.001/finding
# - Config: ~$2/rule/region/month
# - Macie: ~$1/GB scanned (can be expensive, disabled by default)

variable "kms_alias" {
  description = "Alias for the KMS key"
  type        = string
  default     = "control-tower"

  # KMS Key Alias:
  # - Human-readable name for the KMS key
  # - Used in AWS console and CLI
  # - Format: alias/<alias-name>
  # - Must be unique within account and region
}

variable "kms_deletion_window" {
  description = "KMS key deletion window in days"
  type        = number
  default     = 30

  # Validation: AWS requires 7-30 day deletion window
  # KMS Key Deletion:
  # - Provides safety window to recover from accidental deletion
  # - Key is disabled immediately, deleted after window expires
  # - During window: Key cannot be used but can be recovered
  # - After window: Key is permanently deleted (data unrecoverable)
  #
  # Recommendations:
  # - Production: 30 days (maximum safety)
  # - Non-production: 7-14 days (faster cleanup)
  # - Never use less than 7 days
  validation {
    condition     = var.kms_deletion_window >= 7 && var.kms_deletion_window <= 30
    error_message = "KMS deletion window must be between 7 and 30 days."
  }
}

variable "kms_multi_region" {
  description = "Enable multi-region KMS key"
  type        = bool
  default     = false

  # Multi-Region KMS Keys:
  # - Replicate key material across multiple regions
  # - Same key ID in all regions (simplifies cross-region operations)
  # - Automatic synchronization of key policies and grants
  # - Higher cost (~2x single-region key)
  #
  # Use Cases:
  # - Disaster recovery across regions
  # - Global applications requiring consistent encryption
  # - Cross-region data replication (S3, DynamoDB)
  #
  # Considerations:
  # - Not needed if workloads are single-region
  # - Can create separate keys per region if needed
  # - Default: false (most deployments are single-region)
}

variable "guardduty_finding_frequency" {
  description = "GuardDuty finding publishing frequency"
  type        = string
  default     = "FIFTEEN_MINUTES"

  # Validation: AWS supports three frequencies
  # GuardDuty Finding Frequency:
  # - How often GuardDuty publishes findings to CloudWatch Events
  # - Does NOT affect detection speed (always real-time)
  # - Only affects notification/integration frequency
  #
  # Options:
  # - FIFTEEN_MINUTES: Fastest notifications (recommended for production)
  # - ONE_HOUR: Balanced (suitable for most environments)
  # - SIX_HOURS: Slowest (only for low-priority environments)
  #
  # Impact:
  # - Faster frequency = quicker response to threats
  # - No cost difference between frequencies
  # - Recommendation: Use FIFTEEN_MINUTES for production
  validation {
    condition     = contains(["FIFTEEN_MINUTES", "ONE_HOUR", "SIX_HOURS"], var.guardduty_finding_frequency)
    error_message = "Must be FIFTEEN_MINUTES, ONE_HOUR, or SIX_HOURS."
  }
}

variable "enable_pci_dss" {
  description = "Enable PCI DSS compliance standard in Security Hub"
  type        = bool
  default     = false

  # PCI DSS (Payment Card Industry Data Security Standard):
  # - Required if processing, storing, or transmitting payment card data
  # - Comprehensive security requirements (12 requirements, 78 sub-requirements)
  # - Security Hub provides automated compliance checks
  #
  # When to Enable:
  # - Processing credit/debit card transactions
  # - Storing cardholder data
  # - Transmitting payment information
  #
  # When to Disable:
  # - No payment card data in environment
  # - Additional cost (~$0.001/check)
  # - Reduces noise if not applicable
  #
  # Default: false (not all organizations process payment cards)
}

variable "config_delivery_frequency" {
  description = "AWS Config snapshot delivery frequency"
  type        = string
  default     = "TwentyFour_Hours"

  # Validation: AWS supports five frequencies
  # AWS Config Snapshots:
  # - Periodic snapshots of resource configurations
  # - Delivered to S3 for long-term storage and analysis
  # - Separate from continuous recording (always active)
  #
  # Options:
  # - One_Hour: Most frequent (highest cost, most granular)
  # - Three_Hours: Frequent (balanced)
  # - Six_Hours: Moderate (suitable for most environments)
  # - Twelve_Hours: Infrequent (cost-conscious)
  # - TwentyFour_Hours: Daily (recommended, lowest cost)
  #
  # Considerations:
  # - More frequent = higher S3 storage costs
  # - Continuous recording captures all changes regardless
  # - Daily snapshots sufficient for most compliance requirements
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

variable "enable_macie" {
  description = "Enable Amazon Macie for data discovery and protection"
  type        = bool
  default     = false

  # Amazon Macie:
  # - Automated sensitive data discovery in S3
  # - Uses machine learning to identify PII, PHI, financial data
  # - Provides data security and privacy insights
  #
  # Cost Warning:
  # - Charges per GB of data scanned (~$1/GB)
  # - Can be expensive for large S3 buckets
  # - Costs can add up quickly in data-heavy environments
  #
  # When to Enable:
  # - Need to discover sensitive data in S3
  # - Compliance requirements (GDPR, HIPAA, PCI DSS)
  # - Data classification initiatives
  # - Security audits
  #
  # When to Disable:
  # - No sensitive data in S3
  # - Cost concerns
  # - Already have data classification process
  #
  # Default: false (due to cost, enable only when needed)
}

variable "macie_finding_frequency" {
  description = "Macie finding publishing frequency"
  type        = string
  default     = "FIFTEEN_MINUTES"

  # Validation: AWS supports three frequencies
  # Macie Finding Frequency:
  # - How often Macie publishes findings to EventBridge
  # - Similar to GuardDuty frequency setting
  #
  # Options:
  # - FIFTEEN_MINUTES: Fastest notifications
  # - ONE_HOUR: Balanced
  # - SIX_HOURS: Slowest
  #
  # Recommendation: FIFTEEN_MINUTES for timely data protection alerts
  validation {
    condition     = contains(["FIFTEEN_MINUTES", "ONE_HOUR", "SIX_HOURS"], var.macie_finding_frequency)
    error_message = "Must be FIFTEEN_MINUTES, ONE_HOUR, or SIX_HOURS."
  }
}

# ============================================================================
# Networking Configuration
# ============================================================================
# Configures centralized networking infrastructure using AWS Transit Gateway
# and Network Firewall for hub-and-spoke topology with centralized traffic
# inspection and filtering.
#
# Architecture:
# - Transit Gateway: Central hub connecting all VPCs
# - Inspection VPC: Dedicated VPC for traffic inspection (3 AZs)
# - Network Firewall: Stateful/stateless traffic filtering
# - DNS Firewall: Domain-based filtering for DNS queries
# - NAT Gateways: Highly available outbound internet access
#
# Benefits:
# - Centralized security controls
# - Simplified network management
# - Consistent traffic inspection
# - Reduced operational complexity
# - Better visibility and logging
#
# Cost Considerations:
# - Transit Gateway: ~$36/month + $0.02/GB
# - Network Firewall: ~$395/month/AZ + $0.065/GB
# - NAT Gateway: ~$32/month/AZ + $0.045/GB
# - Total: ~$1,500-2,000/month for 3-AZ deployment
#
# When to Enable:
# - Multiple VPCs requiring connectivity
# - Need centralized traffic inspection
# - Compliance requirements for network security
# - Hub-and-spoke network topology
#
# When to Disable:
# - Single VPC deployment
# - Cost constraints
# - Simple network requirements

variable "enable_centralized_networking" {
  description = "Enable centralized networking with Transit Gateway and Network Firewall"
  type        = bool
  default     = true

  # Centralized Networking:
  # - Deploys full networking module with Transit Gateway and Network Firewall
  # - Significant cost (~$1,500-2,000/month)
  # - Provides enterprise-grade network security
  #
  # Set to false to:
  # - Reduce costs in non-production environments
  # - Skip networking for simple deployments
  # - Use alternative networking solutions
}

variable "inspection_vpc_cidr" {
  description = "CIDR block for inspection VPC"
  type        = string
  default     = "10.0.0.0/16"

  # Validation: Ensure valid CIDR block
  # Inspection VPC CIDR:
  # - Dedicated VPC for Network Firewall and NAT Gateways
  # - Should not overlap with spoke VPC CIDRs
  # - /16 provides 65,536 IP addresses (more than enough)
  #
  # Subnet Allocation (per AZ):
  # - Public subnet: /24 (256 IPs) - NAT Gateways, IGW
  # - Firewall subnet: /24 (256 IPs) - Network Firewall endpoints
  # - Private subnet: /24 (256 IPs) - Future use
  #
  # Planning:
  # - Reserve non-overlapping CIDR for inspection VPC
  # - Document CIDR allocation for spoke VPCs
  # - Consider future growth and expansion
  validation {
    condition     = can(cidrhost(var.inspection_vpc_cidr, 0))
    error_message = "Must be a valid CIDR block."
  }
}

variable "network_availability_zones" {
  description = "Availability zones for network resources"
  type        = list(string)
  default     = []

  # Availability Zones:
  # - List of AZs for high availability deployment
  # - Empty list = auto-select first 3 AZs in region
  # - Specify explicitly for control over AZ selection
  #
  # High Availability:
  # - Minimum 2 AZs recommended
  # - 3 AZs provides best availability (default)
  # - Each AZ gets: NAT Gateway, Firewall endpoint, subnets
  #
  # Cost vs Availability:
  # - 2 AZs: ~$1,000/month (lower cost, less resilient)
  # - 3 AZs: ~$1,500/month (balanced, recommended)
  # - 4+ AZs: ~$2,000+/month (highest availability, highest cost)
  #
  # Examples:
  # - Sydney: ["ap-southeast-2a", "ap-southeast-2b", "ap-southeast-2c"]
  # - US East: ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "transit_gateway_asn" {
  description = "ASN for Transit Gateway"
  type        = number
  default     = 64512

  # Validation: Must be in private ASN range
  # Transit Gateway ASN (Autonomous System Number):
  # - Used for BGP routing with on-premises networks
  # - Required for VPN and Direct Connect connections
  # - Must be unique if connecting multiple Transit Gateways
  #
  # ASN Ranges:
  # - Private ASN: 64512-65534 (use for internal networks)
  # - Public ASN: Assigned by IANA (use for internet routing)
  #
  # Default: 64512 (first private ASN)
  # Change if:
  # - Connecting to on-premises network with same ASN
  # - Peering with another Transit Gateway
  # - Organization has ASN allocation policy
  validation {
    condition     = var.transit_gateway_asn >= 64512 && var.transit_gateway_asn <= 65534
    error_message = "Transit Gateway ASN must be in private ASN range (64512-65534)."
  }
}

variable "network_firewall_allowed_domains" {
  description = "List of allowed domains for Network Firewall"
  type        = list(string)
  default = [
    ".github.com", # GitHub (code repositories, CI/CD)
    ".docker.com", # Docker Hub (container images)
    ".npmjs.org",  # NPM (JavaScript packages)
    ".pypi.org"    # PyPI (Python packages)
  ]

  # Network Firewall Domain Filtering:
  # - Stateful rule that allows HTTPS traffic to specified domains
  # - Uses SNI (Server Name Indication) for domain matching
  # - Supports wildcards (e.g., .github.com matches api.github.com)
  #
  # Common Domains to Allow:
  # - Package repositories: .npmjs.org, .pypi.org, .maven.org
  # - Cloud services: .amazonaws.com, .azure.com, .googleapis.com
  # - Development tools: .github.com, .gitlab.com, .bitbucket.org
  # - Container registries: .docker.com, .gcr.io, .quay.io
  #
  # Security Considerations:
  # - Start with minimal list, expand as needed
  # - Monitor firewall logs for blocked legitimate traffic
  # - Use specific subdomains when possible (api.github.com vs .github.com)
  # - Document business justification for each domain
}

variable "network_firewall_denied_domains" {
  description = "List of denied domains for Network Firewall"
  type        = list(string)
  default     = []

  # Network Firewall Domain Blocking:
  # - Explicitly block traffic to specified domains
  # - Takes precedence over allowed domains
  # - Useful for blocking known malicious domains
  #
  # Use Cases:
  # - Block known malware C2 domains
  # - Block cryptocurrency mining pools
  # - Block file sharing sites
  # - Block social media (if policy requires)
  #
  # Threat Intelligence:
  # - Integrate with threat feeds
  # - Regularly update blocked domain list
  # - Monitor for false positives
  #
  # Default: Empty (no explicit blocks, rely on threat intelligence)
}

variable "dns_firewall_blocked_domains" {
  description = "List of domains to block via DNS Firewall"
  type        = list(string)
  default     = []

  # DNS Firewall Domain Blocking:
  # - Blocks DNS resolution for specified domains
  # - Prevents connections at DNS layer (before network layer)
  # - More efficient than Network Firewall for known bad domains
  #
  # Difference from Network Firewall:
  # - DNS Firewall: Blocks DNS queries (earlier in connection)
  # - Network Firewall: Blocks network traffic (later in connection)
  #
  # Use Cases:
  # - Block malware domains
  # - Block phishing sites
  # - Block ad/tracking domains
  # - Block inappropriate content
  #
  # Integration:
  # - Can use AWS Managed Domain Lists
  # - Can import threat intelligence feeds
  # - Can create custom block lists
  #
  # Default: Empty (no explicit blocks)
}

variable "dns_firewall_allowed_domains" {
  description = "List of domains to explicitly allow via DNS Firewall"
  type        = list(string)
  default = [
    "*.amazonaws.com", # AWS services
    "*.aws.amazon.com" # AWS documentation and resources
  ]

  # DNS Firewall Domain Allowlist:
  # - Explicitly allow DNS resolution for specified domains
  # - Useful in deny-by-default configurations
  # - Supports wildcards for subdomains
  #
  # AWS Services:
  # - Always allow *.amazonaws.com for AWS API calls
  # - Required for EC2, S3, Lambda, and other AWS services
  # - Without this, AWS services won't function
  #
  # Strategy:
  # - Start with AWS domains
  # - Add business-critical domains
  # - Monitor DNS query logs
  # - Expand allowlist as needed
}

variable "nat_gateway_bandwidth_threshold" {
  description = "NAT Gateway bandwidth threshold in bytes for alarms"
  type        = number
  default     = 10737418240 # 10 GB

  # NAT Gateway Bandwidth Monitoring:
  # - Alerts when bandwidth exceeds threshold
  # - Helps detect:
  #   * Data exfiltration
  #   * Misconfigured applications
  #   * Unexpected traffic patterns
  #   * Cost anomalies
  #
  # Threshold Calculation:
  # - Default: 10 GB (10,737,418,240 bytes)
  # - Adjust based on normal traffic patterns
  # - Monitor for 2-4 weeks, set threshold at 2x normal peak
  #
  # Cost Impact:
  # - NAT Gateway charges $0.045/GB processed
  # - 10 GB = $0.45
  # - 100 GB = $4.50
  # - 1 TB = $45
  #
  # Tuning:
  # - Lower threshold: More sensitive, more alerts
  # - Higher threshold: Less sensitive, may miss anomalies
}

variable "firewall_packet_drop_threshold" {
  description = "Network Firewall packet drop threshold for alarms"
  type        = number
  default     = 1000

  # Network Firewall Packet Drop Monitoring:
  # - Alerts when dropped packets exceed threshold
  # - Indicates:
  #   * Blocked malicious traffic (good)
  #   * Misconfigured firewall rules (bad)
  #   * Legitimate traffic being blocked (bad)
  #
  # Threshold Guidance:
  # - Default: 1000 packets/5 minutes
  # - Adjust based on environment:
  #   * High security: Lower threshold (500)
  #   * Normal: Default threshold (1000)
  #   * High traffic: Higher threshold (5000)
  #
  # Investigation:
  # - Check firewall logs for drop reasons
  # - Identify source/destination of dropped packets
  # - Determine if drops are legitimate or misconfiguration
  # - Adjust firewall rules or threshold accordingly
}

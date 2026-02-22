# ============================================================================
# AWS Control Tower Landing Zone - Enterprise-Grade Multi-Account Setup
# ============================================================================
#
# Purpose:
#   This Terraform configuration deploys a comprehensive AWS Control Tower
#   landing zone with enterprise-grade security, networking, logging, and
#   governance controls. It provides a secure, scalable foundation for
#   multi-account AWS environments.
#
# Architecture Overview:
#   - Control Tower: Automated account provisioning and governance
#   - Organizational Units: Flexible, extensible OU structure (2 to N OUs)
#   - Service Control Policies: 35+ comprehensive SCPs for guardrails
#   - Security Services: KMS, GuardDuty, Security Hub, Config, Macie
#   - Centralized Logging: CloudTrail, S3, CloudWatch with 7-year retention
#   - Centralized Networking: Transit Gateway, Network Firewall, DNS Firewall
#   - Monitoring & Alerting: Two-tier SNS notifications, CloudWatch alarms
#
# Key Features:
#   ✓ Multi-region governance (home region: Sydney/ap-southeast-2)
#   ✓ Extensible OU structure (supports 2 to N organizational units)
#   ✓ 35+ comprehensive SCPs covering all major AWS services
#   ✓ Defense-in-depth security with multiple AWS security services
#   ✓ Centralized audit logging with 7-year retention for compliance
#   ✓ Hub-and-spoke networking with centralized traffic inspection
#   ✓ Automated threat detection and compliance monitoring
#   ✓ Two-tier alerting (security vs operational notifications)
#
# Compliance Standards:
#   - AWS Foundational Security Best Practices
#   - CIS AWS Foundations Benchmark
#   - PCI DSS (optional)
#   - SOC 2, HIPAA logging requirements
#
# Prerequisites:
#   1. AWS Organizations must be enabled
#   2. Must run from management account
#   3. Terraform >= 1.6.0 (for native S3 state locking)
#   4. AWS provider >= 5.0
#
# Deployment Order:
#   1. Validation (management account check)
#   2. Control Tower landing zone
#   3. Organizational units
#   4. SCP policies and attachments
#   5. Security services (KMS, GuardDuty, Security Hub, Config)
#   6. Logging infrastructure (CloudTrail, S3, CloudWatch)
#   7. Networking infrastructure (Transit Gateway, Network Firewall)
#   8. Monitoring and alerting (SNS, CloudWatch alarms, EventBridge)
#
# Usage:
#   terraform init
#   terraform plan -var-file="terraform.tfvars.production"
#   terraform apply -var-file="terraform.tfvars.production"
#
# Documentation:
#   See docs/ folder for comprehensive guides:
#   - docs/DEPLOYMENT_GUIDE.md - Step-by-step deployment instructions
#   - docs/ARCHITECTURE.md - Architecture and design decisions
#   - docs/SECURITY.md - Security controls and compliance
#   - docs/NETWORKING.md - Network architecture and traffic flows
#   - docs/SCP_POLICIES.md - Service Control Policy details
#
# Maintainer: Infrastructure Team
# Version: 1.0.0
# Last Updated: 2024
#
# ============================================================================

# ============================================================================
# Provider Configuration
# ============================================================================
# AWS provider configuration with default tags applied to all resources.
# Default tags ensure consistent tagging across the organization for
# cost allocation, compliance, and resource management.

provider "aws" {
  region = var.home_region

  # Default tags applied to all resources created by this provider
  # Individual resources can add additional tags via merge()
  default_tags {
    tags = var.default_tags
  }
}

# ============================================================================
# Data Sources - Retrieve AWS Account and Organization Information
# ============================================================================
# These data sources fetch information about the current AWS account and
# organization to validate deployment prerequisites and ensure we're running
# in the correct context (management account).

# Get current AWS account ID and ARN
# Used for validation and resource naming throughout the deployment
data "aws_caller_identity" "current" {}

# Get AWS Organizations information
# Required to validate we're in the management account and to retrieve root OU ID
data "aws_organizations_organization" "current" {}

# ============================================================================
# Validation - Ensure Deployment Prerequisites
# ============================================================================
# Control Tower MUST be deployed from the AWS Organizations management account.
# This validation prevents accidental deployment from member accounts which
# would fail and potentially cause issues.

resource "null_resource" "validate_management_account" {
  lifecycle {
    precondition {
      condition     = data.aws_caller_identity.current.account_id == data.aws_organizations_organization.current.master_account_id
      error_message = "Control Tower must be deployed from the AWS Organizations management account."
    }
  }
}

# ============================================================================
# Control Tower Module - AWS Control Tower Landing Zone Setup
# ============================================================================
# Deploys AWS Control Tower landing zone with specified governance regions.
# Control Tower provides automated account provisioning, guardrails (SCPs),
# and centralized logging/monitoring across the organization.
#
# Key Features:
# - Multi-region governance (home region + additional regions)
# - Automated account vending
# - Baseline security guardrails
# - Centralized audit and log archive accounts
#
# Dependencies: Must run after management account validation

module "control_tower" {
  source = "./modules/control-tower"

  # Regions where Control Tower will enforce governance
  # Must include us-east-1 for global services (IAM, CloudFront, etc.)
  governed_regions = var.governed_regions

  # Control Tower version - determines available features and guardrails
  landing_zone_version = var.landing_zone_version

  depends_on = [null_resource.validate_management_account]
}

# ============================================================================
# Organizational Units Module - OU Structure Creation
# ============================================================================
# Creates a flexible, extensible organizational unit (OU) structure.
# OUs are logical groupings of AWS accounts that share common policies and
# governance requirements (e.g., Production, Non-Production, Security, etc.)
#
# Design:
# - Fully dynamic: supports 2 to N organizational units
# - Environment-based: each OU can represent different environments
# - Policy-ready: OUs serve as attachment points for SCPs
#
# Dependencies: Requires Control Tower root OU ID

module "organizational_units" {
  source = "./modules/organizational-units"

  # Root OU ID from Control Tower - parent for all custom OUs
  parent_id = module.control_tower.root_id

  # Map of OUs to create - fully extensible via variables
  # Each OU includes name, environment tag, and custom tags
  organizational_units = var.organizational_units

  depends_on = [module.control_tower]
}

# ============================================================================
# SCP Policies Module - Service Control Policy Definitions
# ============================================================================
# Creates comprehensive Service Control Policies (SCPs) for governance.
# SCPs are organization-level policies that set maximum permissions for
# accounts, acting as guardrails to prevent unauthorized actions.
#
# Policy Categories:
# - Core Security: Root user restrictions, MFA requirements, region limits
# - Encryption: Enforce encryption at rest and in transit
# - Network Security: VPC, security group, and network controls
# - Data Protection: S3, RDS, and database security
# - IAM Security: Identity and access management controls
# - Compliance: Logging, monitoring, and audit requirements
#
# Total: 35+ comprehensive policies covering all major AWS services

module "scp_policies" {
  source = "./modules/scp-policies"

  # List of policy names to enable (from 35+ available policies)
  enabled_policies = var.enabled_scp_policies

  # Allowed AWS regions for workloads (enforced via SCP)
  allowed_regions = var.allowed_regions

  # Allowed EC2 instance types for non-prod (cost control)
  allowed_instance_types = var.allowed_instance_types_nonprod

  depends_on = [module.control_tower]
}

# ============================================================================
# SCP Attachments Module - Policy-to-OU Binding
# ============================================================================
# Attaches SCPs to organizational units and root OU.
# This module handles the complex mapping between policies and OUs,
# supporting both root-level policies (apply to all accounts) and
# OU-specific policies (apply only to accounts in that OU).
#
# Attachment Strategy:
# - Root policies: Apply organization-wide (e.g., deny root user)
# - OU policies: Apply per-environment (e.g., restrict instance types in non-prod)
# - Validation: Ensures all referenced OUs exist before attachment
#
# Dependencies: Requires both policies and OUs to exist first

module "scp_attachments" {
  source = "./modules/scp-attachments"

  # Merged map of all policy attachments (root + OU-specific)
  # Generated in locals.tf with validation
  policy_attachments = local.policy_attachments

  depends_on = [
    module.scp_policies,
    module.organizational_units,
    null_resource.validate_ou_keys
  ]
}

# ============================================================================
# Security Module - Comprehensive Security Services
# ============================================================================
# Implements enterprise-grade security controls across the organization.
# This module deploys and configures multiple AWS security services to
# provide defense-in-depth protection, continuous monitoring, and compliance.
#
# Services Deployed:
# - KMS: Customer-managed encryption keys for data at rest
# - GuardDuty: Intelligent threat detection using ML
# - Security Hub: Centralized security findings and compliance checks
# - AWS Config: Resource configuration tracking and compliance rules
# - Access Analyzer: IAM policy analysis for unintended access
# - Macie: Sensitive data discovery and protection (optional)
#
# Compliance Standards:
# - AWS Foundational Security Best Practices
# - CIS AWS Foundations Benchmark
# - PCI DSS (optional)
#
# Integration:
# - All findings sent to Security Hub for centralization
# - Critical alerts sent to SNS for immediate notification
# - Config rules evaluate compliance continuously
#
# Dependencies: Must run after Control Tower to ensure organization exists

module "security" {
  source = "./modules/security"

  # Account and region context
  account_id = data.aws_caller_identity.current.account_id
  region     = var.home_region

  # KMS Configuration - Customer-managed encryption
  kms_alias           = var.kms_alias
  kms_deletion_window = var.kms_deletion_window # 7-30 days safety window
  kms_multi_region    = var.kms_multi_region    # Enable for DR scenarios

  # GuardDuty Configuration - Threat detection
  guardduty_finding_frequency = var.guardduty_finding_frequency # How often to publish findings

  # Security Hub Configuration - Compliance standards
  enable_pci_dss = var.enable_pci_dss # Enable if processing payment data

  # AWS Config Configuration - Resource compliance tracking
  config_recorder_name         = "${var.project_name}-config-recorder"
  config_delivery_channel_name = "${var.project_name}-config-delivery"
  config_delivery_frequency    = var.config_delivery_frequency # Snapshot frequency

  # Logging Configuration - Where to store security logs
  log_bucket_name = "${var.project_name}-logs-${data.aws_caller_identity.current.account_id}"

  # Notification Configuration - Where to send security alerts
  sns_topic_arn = aws_sns_topic.security_notifications.arn

  # Access Analyzer Configuration - IAM policy analysis
  access_analyzer_name = "${var.project_name}-access-analyzer"

  # Macie Configuration - Sensitive data discovery (optional, can be expensive)
  enable_macie            = var.enable_macie
  macie_finding_frequency = var.macie_finding_frequency

  tags = local.common_tags

  depends_on = [module.control_tower]
}

# ============================================================================
# Networking Module - Centralized Network Infrastructure
# ============================================================================
# Implements enterprise-grade centralized networking architecture using
# AWS Transit Gateway and Network Firewall for hub-and-spoke topology.
# This provides centralized traffic inspection, filtering, and routing.
#
# Architecture Components:
# - Transit Gateway: Central hub for VPC connectivity across accounts/regions
# - Inspection VPC: Dedicated VPC for traffic inspection (3 AZs for HA)
# - Network Firewall: Stateful/stateless traffic filtering and IDS/IPS
# - DNS Firewall: Domain-based filtering for DNS queries
# - NAT Gateways: Highly available outbound internet access (one per AZ)
# - VPC Flow Logs: Network traffic logging for security analysis
# - Network Access Analyzer: Verify network segmentation and access paths
#
# Traffic Flow:
# 1. Spoke VPCs attach to Transit Gateway
# 2. Traffic routes through Inspection VPC
# 3. Network Firewall inspects all traffic
# 4. Allowed traffic proceeds to destination
# 5. All traffic logged to S3 and CloudWatch
#
# High Availability:
# - Multi-AZ deployment (3 AZs)
# - Redundant NAT Gateways
# - Automatic failover
#
# Security Features:
# - Deep packet inspection
# - Domain filtering (allow/deny lists)
# - IDS/IPS capabilities
# - TLS inspection (optional)
# - Comprehensive logging
#
# Dependencies: Requires security module for KMS encryption and logging module for S3 bucket

module "networking" {
  count = var.enable_centralized_networking ? 1 : 0

  source = "./modules/networking"

  # Naming and identification
  name_prefix = var.project_name

  # Network Configuration
  inspection_vpc_cidr = var.inspection_vpc_cidr        # CIDR for central inspection VPC
  availability_zones  = var.network_availability_zones # AZs for HA deployment
  transit_gateway_asn = var.transit_gateway_asn        # BGP ASN for Transit Gateway

  # Network Firewall Rules - Application layer filtering
  allowed_domains = var.network_firewall_allowed_domains # Domains to allow (e.g., .github.com)
  denied_domains  = var.network_firewall_denied_domains  # Domains to explicitly block

  # DNS Firewall Rules - DNS query filtering
  dns_blocked_domains = var.dns_firewall_blocked_domains # Block DNS resolution
  dns_allowed_domains = var.dns_firewall_allowed_domains # Allow DNS resolution

  # Logging Configuration
  log_bucket_name    = "${var.project_name}-logs-${data.aws_caller_identity.current.account_id}"
  log_retention_days = var.cloudwatch_retention_days
  kms_key_id         = module.security.kms_key_id # Encrypt logs at rest

  # Monitoring and Alerting
  sns_topic_arn                   = aws_sns_topic.operational_notifications.arn
  nat_gateway_bandwidth_threshold = var.nat_gateway_bandwidth_threshold # Alert on high bandwidth
  firewall_packet_drop_threshold  = var.firewall_packet_drop_threshold  # Alert on dropped packets

  tags = local.common_tags

  depends_on = [module.security, module.logging]
}

# ============================================================================
# Logging Module - Centralized Audit Logging and Monitoring
# ============================================================================
# Implements comprehensive centralized logging for security, compliance,
# and operational visibility across the entire AWS organization.
#
# Logging Components:
# - S3 Log Archive: Centralized storage for all logs (7-year retention)
# - CloudTrail: Organization-wide API activity logging
# - CloudWatch Logs: Real-time log aggregation and analysis
# - Metric Filters: Extract metrics from logs for alerting
# - CloudWatch Alarms: Alert on security and operational events
#
# CloudTrail Features:
# - Organization trail (logs all accounts)
# - Management events (API calls)
# - Data events (S3 and Lambda)
# - Insights events (anomaly detection)
# - Log file validation (integrity checking)
# - Encryption at rest (KMS)
#
# S3 Lifecycle Management:
# - Day 0-90: Standard storage (frequent access)
# - Day 90-365: Glacier (infrequent access, lower cost)
# - Day 365-2555: Deep Archive (long-term retention, lowest cost)
# - Day 2555+: Expiration (7 years for compliance)
#
# Monitored Security Events:
# - Unauthorized API calls
# - IAM policy changes
# - Console sign-in failures
# - VPC configuration changes
# - Security group modifications
# - Root account usage
#
# Compliance:
# - Meets SOC 2, PCI DSS, HIPAA logging requirements
# - Immutable log storage
# - Tamper-evident (log file validation)
# - Long-term retention (7 years)
#
# Dependencies: Requires security module for KMS encryption

module "logging" {
  source = "./modules/logging"

  # S3 Bucket Configuration
  log_bucket_name = "${var.project_name}-logs-${data.aws_caller_identity.current.account_id}"

  # CloudTrail Configuration
  cloudtrail_name = "${var.project_name}-organization-trail"

  # Encryption and Notifications
  kms_key_id    = module.security.kms_key_id               # Encrypt logs at rest
  sns_topic_arn = aws_sns_topic.security_notifications.arn # Alert on critical events

  # Retention Configuration - Lifecycle management
  log_retention_days    = var.log_retention_days    # Total retention (2555 days = 7 years)
  log_transition_days   = var.log_transition_days   # Days before moving to Glacier (90)
  log_deep_archive_days = var.log_deep_archive_days # Days before Deep Archive (365)

  # CloudWatch Logs Retention
  cloudwatch_retention_days = var.cloudwatch_retention_days # Real-time log retention (365 days)

  # CloudWatch Alarm Thresholds - Tune based on environment
  unauthorized_api_threshold       = var.unauthorized_api_threshold       # Failed API calls
  iam_changes_threshold            = var.iam_changes_threshold            # IAM policy modifications
  signin_failures_threshold        = var.signin_failures_threshold        # Console login failures
  vpc_changes_threshold            = var.vpc_changes_threshold            # VPC configuration changes
  security_group_changes_threshold = var.security_group_changes_threshold # SG modifications

  tags = local.common_tags

  depends_on = [module.security]
}

# ============================================================================
# SNS Topics for Notifications - Two-Tier Alerting System
# ============================================================================
# Implements a two-tier notification system to separate critical security
# alerts from routine operational notifications, preventing alert fatigue.
#
# Tier 1: Security Notifications (High Priority)
# - Purpose: Critical security events requiring immediate attention
# - Examples: GuardDuty findings, Security Hub alerts, unauthorized API calls
# - Audience: Security team, SOC, CISO
# - Response: Immediate investigation required
#
# Tier 2: Operational Notifications (Normal Priority)
# - Purpose: Routine operational events and informational alerts
# - Examples: Network bandwidth alerts, Control Tower events, Config changes
# - Audience: Operations team, DevOps, platform engineers
# - Response: Review during business hours
#
# Security Features:
# - KMS encryption for messages at rest
# - SNS topic policies restrict access to AWS services only
# - Email subscriptions require confirmation
# - All notifications logged to CloudTrail
#
# Integration Points:
# - Security Hub → Security SNS
# - GuardDuty → Security SNS
# - CloudWatch Alarms (security) → Security SNS
# - CloudWatch Alarms (operational) → Operational SNS
# - EventBridge rules → Operational SNS

# ============================================================================
# Security Notifications Topic (High Priority)
# ============================================================================
# Critical security alerts that require immediate attention and investigation.
# All messages encrypted with KMS for data protection.

resource "aws_sns_topic" "security_notifications" {
  name              = "${var.project_name}-security-notifications"
  display_name      = "Security Notifications"
  kms_master_key_id = module.security.kms_key_id # Encrypt messages at rest

  tags = merge(
    local.common_tags,
    {
      Priority = "High"
      Type     = "Security"
    }
  )
}

# Email subscriptions for security team
# Each email will receive a confirmation email before activation
resource "aws_sns_topic_subscription" "security_email" {
  for_each = toset(var.security_notification_emails)

  topic_arn = aws_sns_topic.security_notifications.arn
  protocol  = "email"
  endpoint  = each.value
}

# ============================================================================
# Operational Notifications Topic (Normal Priority)
# ============================================================================
# Routine operational alerts for monitoring and maintenance activities.
# Less urgent than security notifications but still important for operations.

resource "aws_sns_topic" "operational_notifications" {
  name              = "${var.project_name}-operational-notifications"
  display_name      = "Operational Notifications"
  kms_master_key_id = module.security.kms_key_id # Encrypt messages at rest

  tags = merge(
    local.common_tags,
    {
      Priority = "Normal"
      Type     = "Operational"
    }
  )
}

# Email subscriptions for operations team
# Each email will receive a confirmation email before activation
resource "aws_sns_topic_subscription" "operational_email" {
  for_each = toset(var.operational_notification_emails)

  topic_arn = aws_sns_topic.operational_notifications.arn
  protocol  = "email"
  endpoint  = each.value
}

# ============================================================================
# CloudWatch Log Group for Control Tower Events
# ============================================================================
# Dedicated log group for Control Tower lifecycle events and operations.
# Provides visibility into Control Tower activities like account creation,
# guardrail enforcement, and landing zone updates.
#
# Features:
# - Long-term retention (configurable, default 365 days)
# - KMS encryption for compliance
# - Integration with CloudWatch Insights for analysis
#
# Use Cases:
# - Audit Control Tower operations
# - Troubleshoot account provisioning issues
# - Track guardrail violations
# - Monitor landing zone updates

resource "aws_cloudwatch_log_group" "control_tower" {
  name              = "/aws/controltower/${var.project_name}"
  retention_in_days = var.cloudwatch_retention_days # How long to keep logs
  kms_key_id        = module.security.kms_key_id    # Encrypt logs at rest

  tags = local.common_tags
}

# ============================================================================
# EventBridge Rule for Control Tower Events
# ============================================================================
# Captures Control Tower lifecycle events from CloudTrail and routes them
# to SNS for notification. This provides real-time awareness of Control
# Tower operations across the organization.
#
# Captured Events:
# - Account creation/deletion
# - Guardrail enable/disable
# - Landing zone setup/update
# - OU creation/modification
# - Baseline deployment
#
# Event Flow:
# 1. Control Tower performs action
# 2. CloudTrail logs the event
# 3. EventBridge matches the pattern
# 4. Event sent to SNS topic
# 5. Operations team receives email

resource "aws_cloudwatch_event_rule" "control_tower_events" {
  name        = "${var.project_name}-control-tower-events"
  description = "Capture Control Tower lifecycle events"

  # Match all Control Tower events from CloudTrail
  event_pattern = jsonencode({
    source      = ["aws.controltower"]
    detail-type = ["AWS Service Event via CloudTrail"]
  })

  tags = local.common_tags
}

# Route matched events to operational SNS topic
resource "aws_cloudwatch_event_target" "control_tower_sns" {
  rule      = aws_cloudwatch_event_rule.control_tower_events.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.operational_notifications.arn
}

# ============================================================================
# SNS Topic Policies - Allow AWS Services to Publish
# ============================================================================
# These policies grant AWS services permission to publish messages to SNS
# topics. Without these policies, services like CloudWatch and EventBridge
# cannot send notifications.
#
# Security Considerations:
# - Least privilege: Only specific AWS services can publish
# - No cross-account access
# - No public access
# - All publish actions logged to CloudTrail

# Security SNS Topic Policy
# Allows security services to publish critical alerts
resource "aws_sns_topic_policy" "security_notifications" {
  arn = aws_sns_topic.security_notifications.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowAWSServices"
        Effect = "Allow"
        Principal = {
          Service = [
            "events.amazonaws.com",     # EventBridge rules
            "cloudwatch.amazonaws.com", # CloudWatch alarms
            "config.amazonaws.com"      # AWS Config notifications
          ]
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.security_notifications.arn
      }
    ]
  })
}

# Operational SNS Topic Policy
# Allows operational services to publish routine alerts
resource "aws_sns_topic_policy" "operational_notifications" {
  arn = aws_sns_topic.operational_notifications.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowAWSServices"
        Effect = "Allow"
        Principal = {
          Service = [
            "events.amazonaws.com",    # EventBridge rules
            "cloudwatch.amazonaws.com" # CloudWatch alarms
          ]
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.operational_notifications.arn
      }
    ]
  })
}

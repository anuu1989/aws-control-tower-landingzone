# ============================================================================
# Account Vending Module - Automated Account Creation and Bootstrapping
# ============================================================================
# This module provides automated AWS account creation and bootstrapping:
# - Creates AWS accounts in specified OUs
# - Bootstraps accounts with baseline configuration
# - Sets up VPC, security groups, IAM roles
# - Configures logging and monitoring
# - Applies security baselines
#
# Features:
# - Extensible account list
# - Automated bootstrapping
# - Customizable per account
# - Idempotent operations
#
# Cross-Account Access:
# - AWS Organizations automatically creates OrganizationAccountAccessRole
# - This role allows management account to access member accounts
# - Bootstrap modules use this role for initial configuration
# - After bootstrapping, use account-specific IAM roles
#
# ============================================================================

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ============================================================================
# AWS Account Creation
# ============================================================================
# Creates AWS accounts using AWS Organizations.
# Accounts are created in specified OUs with email addresses.

resource "aws_organizations_account" "accounts" {
  for_each = var.accounts

  name      = each.value.name
  email     = each.value.email
  parent_id = each.value.ou_id

  # IAM role for cross-account access
  role_name = each.value.role_name

  # Close account on destroy (requires manual confirmation)
  close_on_deletion = var.close_on_deletion

  # Tags for the account
  tags = merge(
    var.tags,
    each.value.tags,
    {
      AccountKey  = each.key
      Environment = each.value.environment
      ManagedBy   = "Terraform"
    }
  )

  lifecycle {
    # Prevent accidental account deletion
    prevent_destroy = true
  }
}

# ============================================================================
# Wait for Account to be Ready
# ============================================================================
# Accounts need time to be fully provisioned before bootstrapping

resource "time_sleep" "wait_for_account" {
  for_each = var.accounts

  depends_on = [aws_organizations_account.accounts]

  create_duration = "60s"

  triggers = {
    account_id = aws_organizations_account.accounts[each.key].id
  }
}

# ============================================================================
# Provider Configuration Note
# ============================================================================
# Provider aliases cannot be used with for_each loops.
# Each bootstrap module will use the default provider and handle
# cross-account access through AWS Organizations permissions.
# The OrganizationAccountAccessRole is automatically created by AWS
# when an account is created through Organizations.

# ============================================================================
# Account Bootstrapping - VPC
# ============================================================================
# Creates baseline VPC configuration in each account

module "account_vpc" {
  for_each = var.enable_bootstrapping ? var.accounts : {}

  source = "./bootstrap/vpc"

  account_id   = aws_organizations_account.accounts[each.key].id
  account_name = each.value.name
  environment  = each.value.environment

  # VPC Configuration
  vpc_cidr             = each.value.vpc_cidr
  availability_zones   = each.value.availability_zones
  enable_nat_gateway   = each.value.enable_nat_gateway
  single_nat_gateway   = each.value.single_nat_gateway
  enable_vpn_gateway   = each.value.enable_vpn_gateway
  enable_dns_hostnames = true
  enable_dns_support   = true

  # VPC Flow Logs
  enable_flow_logs         = true
  flow_logs_retention_days = var.flow_logs_retention_days

  tags = merge(var.tags, each.value.tags)

  depends_on = [time_sleep.wait_for_account]
}

# ============================================================================
# Account Bootstrapping - Security Groups
# ============================================================================
# Creates baseline security groups in each account

module "account_security_groups" {
  for_each = var.enable_bootstrapping ? var.accounts : {}

  source = "./bootstrap/security-groups"

  vpc_id       = module.account_vpc[each.key].vpc_id
  vpc_cidr     = each.value.vpc_cidr
  account_name = each.value.name
  environment  = each.value.environment

  # Security group rules
  allowed_ssh_cidrs   = each.value.allowed_ssh_cidrs
  allowed_https_cidrs = each.value.allowed_https_cidrs

  tags = merge(var.tags, each.value.tags)

  depends_on = [module.account_vpc]
}

# ============================================================================
# Account Bootstrapping - IAM Roles
# ============================================================================
# Creates baseline IAM roles for common use cases

module "account_iam" {
  for_each = var.enable_bootstrapping ? var.accounts : {}

  source = "./bootstrap/iam"

  account_id   = aws_organizations_account.accounts[each.key].id
  account_name = each.value.name
  environment  = each.value.environment

  # Management account for cross-account access
  management_account_id = var.management_account_id

  # Enable specific roles
  enable_admin_role      = each.value.enable_admin_role
  enable_readonly_role   = each.value.enable_readonly_role
  enable_developer_role  = each.value.enable_developer_role
  enable_terraform_role  = true

  tags = merge(var.tags, each.value.tags)

  depends_on = [time_sleep.wait_for_account]
}

# ============================================================================
# Account Bootstrapping - CloudWatch Logs
# ============================================================================
# Sets up CloudWatch log groups and metric filters

module "account_logging" {
  for_each = var.enable_bootstrapping ? var.accounts : {}

  source = "./bootstrap/logging"

  account_name       = each.value.name
  environment        = each.value.environment
  retention_days     = var.cloudwatch_retention_days
  kms_key_id         = var.kms_key_id
  log_bucket_name    = var.central_log_bucket
  management_account = var.management_account_id

  tags = merge(var.tags, each.value.tags)

  depends_on = [time_sleep.wait_for_account]
}

# ============================================================================
# Account Bootstrapping - Security Baseline
# ============================================================================
# Enables security services and configurations

module "account_security" {
  for_each = var.enable_bootstrapping ? var.accounts : {}

  source = "./bootstrap/security"

  account_id   = aws_organizations_account.accounts[each.key].id
  account_name = each.value.name
  environment  = each.value.environment

  # Security services
  enable_guardduty    = each.value.enable_guardduty
  enable_securityhub  = each.value.enable_securityhub
  enable_config       = each.value.enable_config
  enable_access_analyzer = each.value.enable_access_analyzer

  # Encryption
  kms_key_id = var.kms_key_id

  # Notifications
  sns_topic_arn = var.security_sns_topic_arn

  # AWS Config
  config_bucket_name = var.config_bucket_name

  tags = merge(var.tags, each.value.tags)

  depends_on = [time_sleep.wait_for_account]
}

# ============================================================================
# Account Bootstrapping - S3 Buckets
# ============================================================================
# Creates baseline S3 buckets with security configurations

module "account_s3" {
  for_each = var.enable_bootstrapping && var.create_baseline_buckets ? var.accounts : {}

  source = "./bootstrap/s3"

  account_id   = aws_organizations_account.accounts[each.key].id
  account_name = each.value.name
  environment  = each.value.environment

  # Bucket configuration
  create_logs_bucket    = true
  create_backups_bucket = true
  create_data_bucket    = each.value.create_data_bucket

  # Encryption
  kms_key_id = var.kms_key_id

  # Lifecycle
  logs_retention_days    = var.s3_logs_retention_days
  backups_retention_days = var.s3_backups_retention_days

  tags = merge(var.tags, each.value.tags)

  depends_on = [time_sleep.wait_for_account]
}

# ============================================================================
# Account Bootstrapping - SSM Parameters
# ============================================================================
# Stores account configuration in SSM Parameter Store

resource "aws_ssm_parameter" "account_config" {
  for_each = var.enable_bootstrapping ? var.accounts : {}

  name        = "/account/config"
  description = "Account configuration parameters"
  type        = "String"
  value = jsonencode({
    account_id   = aws_organizations_account.accounts[each.key].id
    account_name = each.value.name
    environment  = each.value.environment
    ou_id        = each.value.ou_id
    vpc_id       = module.account_vpc[each.key].vpc_id
    vpc_cidr     = each.value.vpc_cidr
    created_at   = timestamp()
  })

  tags = merge(var.tags, each.value.tags)

  depends_on = [module.account_vpc]
}

# ============================================================================
# Account Tagging
# ============================================================================
# Apply additional tags to accounts

resource "aws_organizations_resource_tags" "account_tags" {
  for_each = var.accounts

  resource_id = aws_organizations_account.accounts[each.key].id

  tags = merge(
    var.tags,
    each.value.tags,
    {
      Bootstrapped = var.enable_bootstrapping ? "true" : "false"
      VPCCreated   = var.enable_bootstrapping ? "true" : "false"
    }
  )
}

# ============================================================================
# Account Outputs to SSM (Management Account)
# ============================================================================
# Store account information in management account for reference

resource "aws_ssm_parameter" "account_inventory" {
  for_each = var.accounts

  name        = "/accounts/${each.key}/info"
  description = "Account information for ${each.value.name}"
  type        = "String"
  value = jsonencode({
    account_id   = aws_organizations_account.accounts[each.key].id
    account_name = each.value.name
    email        = each.value.email
    environment  = each.value.environment
    ou_id        = each.value.ou_id
    vpc_id       = var.enable_bootstrapping ? module.account_vpc[each.key].vpc_id : null
    vpc_cidr     = each.value.vpc_cidr
    created_at   = aws_organizations_account.accounts[each.key].joined_timestamp
  })

  tags = merge(
    var.tags,
    {
      AccountKey = each.key
    }
  )
}

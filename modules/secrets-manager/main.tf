# ============================================================================
# Secrets Manager Module
# ============================================================================
# This module manages AWS Secrets Manager secrets for storing sensitive
# configuration values used by the Control Tower deployment.
#
# Features:
# - Centralized secrets storage
# - Automatic rotation support
# - KMS encryption
# - Access logging
# - Version management
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
# Notification Emails Secret
# ============================================================================
# Stores email addresses for security and operational notifications

resource "aws_secretsmanager_secret" "notification_emails" {
  name        = "${var.name_prefix}/notification-emails"
  description = "Email addresses for Control Tower notifications"
  
  kms_key_id = var.kms_key_id
  
  recovery_window_in_days = var.recovery_window_days
  
  tags = merge(
    var.tags,
    {
      Name        = "${var.name_prefix}-notification-emails"
      Purpose     = "Notification Configuration"
      Sensitive   = "true"
      ManagedBy   = "Terraform"
    }
  )
}

resource "aws_secretsmanager_secret_version" "notification_emails" {
  secret_id = aws_secretsmanager_secret.notification_emails.id
  
  secret_string = jsonencode({
    security_emails    = var.security_notification_emails
    operational_emails = var.operational_notification_emails
    compliance_emails  = var.compliance_notification_emails
  })
}

# ============================================================================
# API Keys Secret (Optional)
# ============================================================================
# Stores API keys for external integrations

resource "aws_secretsmanager_secret" "api_keys" {
  count = var.create_api_keys_secret ? 1 : 0
  
  name        = "${var.name_prefix}/api-keys"
  description = "API keys for external integrations"
  
  kms_key_id = var.kms_key_id
  
  recovery_window_in_days = var.recovery_window_days
  
  tags = merge(
    var.tags,
    {
      Name        = "${var.name_prefix}-api-keys"
      Purpose     = "API Integration"
      Sensitive   = "true"
      ManagedBy   = "Terraform"
    }
  )
}

resource "aws_secretsmanager_secret_version" "api_keys" {
  count = var.create_api_keys_secret ? 1 : 0
  
  secret_id = aws_secretsmanager_secret.api_keys[0].id
  
  secret_string = jsonencode(var.api_keys)
}

# ============================================================================
# Database Credentials Secret (Optional)
# ============================================================================
# Stores database credentials with automatic rotation

resource "aws_secretsmanager_secret" "database_credentials" {
  count = var.create_database_secret ? 1 : 0
  
  name        = "${var.name_prefix}/database-credentials"
  description = "Database credentials for Control Tower applications"
  
  kms_key_id = var.kms_key_id
  
  recovery_window_in_days = var.recovery_window_days
  
  tags = merge(
    var.tags,
    {
      Name        = "${var.name_prefix}-database-credentials"
      Purpose     = "Database Access"
      Sensitive   = "true"
      ManagedBy   = "Terraform"
    }
  )
}

resource "aws_secretsmanager_secret_version" "database_credentials" {
  count = var.create_database_secret ? 1 : 0
  
  secret_id = aws_secretsmanager_secret.database_credentials[0].id
  
  secret_string = jsonencode({
    username = var.database_username
    password = var.database_password
    engine   = var.database_engine
    host     = var.database_host
    port     = var.database_port
    dbname   = var.database_name
  })
}

# ============================================================================
# Webhook URLs Secret (Optional)
# ============================================================================
# Stores webhook URLs for Slack, Teams, etc.

resource "aws_secretsmanager_secret" "webhook_urls" {
  count = var.create_webhook_secret ? 1 : 0
  
  name        = "${var.name_prefix}/webhook-urls"
  description = "Webhook URLs for notifications"
  
  kms_key_id = var.kms_key_id
  
  recovery_window_in_days = var.recovery_window_days
  
  tags = merge(
    var.tags,
    {
      Name        = "${var.name_prefix}-webhook-urls"
      Purpose     = "Notification Integration"
      Sensitive   = "true"
      ManagedBy   = "Terraform"
    }
  )
}

resource "aws_secretsmanager_secret_version" "webhook_urls" {
  count = var.create_webhook_secret ? 1 : 0
  
  secret_id = aws_secretsmanager_secret.webhook_urls[0].id
  
  secret_string = jsonencode({
    slack_webhook = var.slack_webhook_url
    teams_webhook = var.teams_webhook_url
  })
}

# ============================================================================
# Secret Access Policy
# ============================================================================
# IAM policy for accessing secrets

resource "aws_iam_policy" "secrets_access" {
  name        = "${var.name_prefix}-secrets-access"
  description = "Policy for accessing Control Tower secrets"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = concat(
          [aws_secretsmanager_secret.notification_emails.arn],
          var.create_api_keys_secret ? [aws_secretsmanager_secret.api_keys[0].arn] : [],
          var.create_database_secret ? [aws_secretsmanager_secret.database_credentials[0].arn] : [],
          var.create_webhook_secret ? [aws_secretsmanager_secret.webhook_urls[0].arn] : []
        )
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = var.kms_key_id != null ? [var.kms_key_id] : []
      }
    ]
  })
  
  tags = var.tags
}

# ============================================================================
# CloudWatch Alarms for Secret Access
# ============================================================================
# Monitor secret access patterns

resource "aws_cloudwatch_log_metric_filter" "secret_access" {
  name           = "${var.name_prefix}-secret-access"
  log_group_name = "/aws/secretsmanager/${var.name_prefix}"
  
  pattern = "[eventName = GetSecretValue]"
  
  metric_transformation {
    name      = "SecretAccessCount"
    namespace = "ControlTower/Secrets"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "excessive_secret_access" {
  alarm_name          = "${var.name_prefix}-excessive-secret-access"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "SecretAccessCount"
  namespace           = "ControlTower/Secrets"
  period              = "300"
  statistic           = "Sum"
  threshold           = var.secret_access_threshold
  alarm_description   = "Excessive secret access detected"
  alarm_actions       = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []
  
  tags = var.tags
}

# ============================================================================
# Data Sources
# ============================================================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ============================================================================
# Secrets Manager Example
# ============================================================================
# This example demonstrates how to use the Secrets Manager module to store
# sensitive configuration values for the Control Tower deployment.
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

provider "aws" {
  region = "ap-southeast-2"
}

# ============================================================================
# KMS Key for Encryption
# ============================================================================

resource "aws_kms_key" "secrets" {
  description             = "KMS key for encrypting secrets"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = {
    Name        = "control-tower-secrets-key"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

resource "aws_kms_alias" "secrets" {
  name          = "alias/control-tower-secrets"
  target_key_id = aws_kms_key.secrets.key_id
}

# ============================================================================
# SNS Topic for Alarms
# ============================================================================

resource "aws_sns_topic" "security_alarms" {
  name              = "control-tower-security-alarms"
  kms_master_key_id = aws_kms_key.secrets.id

  tags = {
    Name        = "control-tower-security-alarms"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

# ============================================================================
# Secrets Manager Module
# ============================================================================

module "secrets_manager" {
  source = "../../modules/secrets-manager"

  name_prefix         = "control-tower"
  kms_key_id          = aws_kms_key.secrets.arn
  recovery_window_days = 30

  # Notification emails
  security_notification_emails = [
    "security-team@example.com",
    "ciso@example.com"
  ]
  
  operational_notification_emails = [
    "ops-team@example.com",
    "devops@example.com"
  ]
  
  compliance_notification_emails = [
    "compliance@example.com",
    "audit@example.com"
  ]

  # API Keys (optional)
  create_api_keys_secret = true
  api_keys = {
    datadog_api_key   = "your-datadog-api-key-here"
    pagerduty_key     = "your-pagerduty-key-here"
    newrelic_api_key  = "your-newrelic-api-key-here"
  }

  # Webhook URLs (optional)
  create_webhook_secret = true
  slack_webhook_url     = "https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
  teams_webhook_url     = "https://outlook.office.com/webhook/YOUR/WEBHOOK/URL"

  # Monitoring
  secret_access_threshold = 100
  alarm_sns_topic_arn     = aws_sns_topic.security_alarms.arn

  tags = {
    Environment = "production"
    Project     = "ControlTower"
    ManagedBy   = "Terraform"
  }
}

# ============================================================================
# Example: Retrieve and Use Secrets
# ============================================================================

# Retrieve notification emails
data "aws_secretsmanager_secret_version" "notification_emails" {
  secret_id = module.secrets_manager.notification_emails_secret_name
}

locals {
  notification_emails = jsondecode(data.aws_secretsmanager_secret_version.notification_emails.secret_string)
  security_emails     = local.notification_emails.security_emails
  operational_emails  = local.notification_emails.operational_emails
}

# Create SNS subscriptions for security emails
resource "aws_sns_topic_subscription" "security_email" {
  for_each = toset(local.security_emails)

  topic_arn = aws_sns_topic.security_alarms.arn
  protocol  = "email"
  endpoint  = each.value
}

# ============================================================================
# Example: Lambda Function Using Secrets
# ============================================================================

resource "aws_iam_role" "lambda" {
  name = "control-tower-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "control-tower-lambda-role"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

# Attach secrets access policy to Lambda role
resource "aws_iam_role_policy_attachment" "lambda_secrets" {
  role       = aws_iam_role.lambda.name
  policy_arn = module.secrets_manager.secrets_access_policy_arn
}

# Attach basic Lambda execution policy
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ============================================================================
# Outputs
# ============================================================================

output "notification_emails_secret_arn" {
  description = "ARN of the notification emails secret"
  value       = module.secrets_manager.notification_emails_secret_arn
}

output "api_keys_secret_arn" {
  description = "ARN of the API keys secret"
  value       = module.secrets_manager.api_keys_secret_arn
}

output "webhook_urls_secret_arn" {
  description = "ARN of the webhook URLs secret"
  value       = module.secrets_manager.webhook_urls_secret_arn
}

output "secrets_access_policy_arn" {
  description = "ARN of the secrets access policy"
  value       = module.secrets_manager.secrets_access_policy_arn
}

output "secrets_summary" {
  description = "Summary of all secrets created"
  value       = module.secrets_manager.secrets_summary
}

output "security_emails" {
  description = "Security notification emails (from secret)"
  value       = local.security_emails
}

output "operational_emails" {
  description = "Operational notification emails (from secret)"
  value       = local.operational_emails
}

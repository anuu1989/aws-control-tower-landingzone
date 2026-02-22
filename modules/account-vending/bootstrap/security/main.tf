# ============================================================================
# Security Bootstrap Module
# ============================================================================
# Enables security services in the account

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
# GuardDuty
# ============================================================================

resource "aws_guardduty_detector" "main" {
  count = var.enable_guardduty ? 1 : 0

  enable                       = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"

  tags = merge(
    var.tags,
    {
      Name        = "${var.account_name}-guardduty"
      Environment = var.environment
    }
  )
}

# ============================================================================
# Security Hub
# ============================================================================

resource "aws_securityhub_account" "main" {
  count = var.enable_securityhub ? 1 : 0

  enable_default_standards = true
  control_finding_generator = "SECURITY_CONTROL"
  auto_enable_controls      = true
}

resource "aws_securityhub_standards_subscription" "cis" {
  count = var.enable_securityhub ? 1 : 0

  standards_arn = "arn:aws:securityhub:::ruleset/cis-aws-foundations-benchmark/v/1.2.0"
  depends_on    = [aws_securityhub_account.main]
}

resource "aws_securityhub_standards_subscription" "aws_foundational" {
  count = var.enable_securityhub ? 1 : 0

  standards_arn = "arn:aws:securityhub:${data.aws_region.current.name}::standards/aws-foundational-security-best-practices/v/1.0.0"
  depends_on    = [aws_securityhub_account.main]
}

# ============================================================================
# AWS Config
# ============================================================================

resource "aws_config_configuration_recorder" "main" {
  count = var.enable_config ? 1 : 0

  name     = "${var.account_name}-config-recorder"
  role_arn = aws_iam_role.config[0].arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "main" {
  count = var.enable_config ? 1 : 0

  name           = "${var.account_name}-config-delivery"
  s3_bucket_name = var.config_bucket_name

  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_configuration_recorder_status" "main" {
  count = var.enable_config ? 1 : 0

  name       = aws_config_configuration_recorder.main[0].name
  is_enabled = true

  depends_on = [aws_config_delivery_channel.main]
}

resource "aws_iam_role" "config" {
  count = var.enable_config ? 1 : 0

  name = "${var.account_name}-config-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "config" {
  count = var.enable_config ? 1 : 0

  role       = aws_iam_role.config[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/ConfigRole"
}

# ============================================================================
# Access Analyzer
# ============================================================================

resource "aws_accessanalyzer_analyzer" "main" {
  count = var.enable_access_analyzer ? 1 : 0

  analyzer_name = "${var.account_name}-access-analyzer"
  type          = "ACCOUNT"

  tags = merge(
    var.tags,
    {
      Name        = "${var.account_name}-access-analyzer"
      Environment = var.environment
    }
  )
}

# ============================================================================
# EBS Encryption by Default
# ============================================================================

resource "aws_ebs_encryption_by_default" "main" {
  enabled = true
}

# ============================================================================
# S3 Block Public Access (Account Level)
# ============================================================================

resource "aws_s3_account_public_access_block" "main" {
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ============================================================================
# Data Sources
# ============================================================================

data "aws_region" "current" {}

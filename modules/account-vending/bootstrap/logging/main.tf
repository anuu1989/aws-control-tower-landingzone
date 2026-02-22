# ============================================================================
# Logging Bootstrap Module
# ============================================================================
# Sets up CloudWatch Logs and log forwarding

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
# CloudWatch Log Groups
# ============================================================================

resource "aws_cloudwatch_log_group" "application" {
  name              = "/aws/${var.account_name}/application"
  retention_in_days = var.retention_days
  kms_key_id        = var.kms_key_id

  tags = merge(
    var.tags,
    {
      Name        = "${var.account_name}-application-logs"
      Environment = var.environment
      Purpose     = "Application Logs"
    }
  )
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.account_name}"
  retention_in_days = var.retention_days
  kms_key_id        = var.kms_key_id

  tags = merge(
    var.tags,
    {
      Name        = "${var.account_name}-lambda-logs"
      Environment = var.environment
      Purpose     = "Lambda Logs"
    }
  )
}

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/aws/ecs/${var.account_name}"
  retention_in_days = var.retention_days
  kms_key_id        = var.kms_key_id

  tags = merge(
    var.tags,
    {
      Name        = "${var.account_name}-ecs-logs"
      Environment = var.environment
      Purpose     = "ECS Logs"
    }
  )
}

# ============================================================================
# CloudWatch Log Metric Filters
# ============================================================================

resource "aws_cloudwatch_log_metric_filter" "error_count" {
  name           = "${var.account_name}-error-count"
  log_group_name = aws_cloudwatch_log_group.application.name
  pattern        = "[ERROR]"

  metric_transformation {
    name      = "ErrorCount"
    namespace = "${var.account_name}/Application"
    value     = "1"
  }
}

# ============================================================================
# CloudWatch Alarms
# ============================================================================

resource "aws_cloudwatch_metric_alarm" "high_error_rate" {
  alarm_name          = "${var.account_name}-high-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ErrorCount"
  namespace           = "${var.account_name}/Application"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "This metric monitors application error rate"
  treat_missing_data  = "notBreaching"

  tags = merge(
    var.tags,
    {
      Name        = "${var.account_name}-high-error-rate"
      Environment = var.environment
    }
  )
}

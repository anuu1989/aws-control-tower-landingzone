# ============================================================================
# Cost Optimization Module
# ============================================================================
# This module implements cost optimization best practices including:
# - AWS Budgets with alerts
# - Cost anomaly detection
# - Resource tagging enforcement
# - Cost allocation tags
#
# Features:
# - Monthly budget with 80% and 100% thresholds
# - Forecasted budget alerts
# - Cost anomaly detection with SNS notifications
# - Automatic cost reporting
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
# AWS Budgets - Monthly Cost Budget
# ============================================================================
# Creates a monthly budget with alerts at 80% and 100% of limit.
# Sends notifications when actual or forecasted costs exceed thresholds.

resource "aws_budgets_budget" "monthly" {
  name              = "${var.name_prefix}-monthly-budget"
  budget_type       = "COST"
  limit_amount      = var.monthly_budget_limit
  limit_unit        = "USD"
  time_period_start = formatdate("YYYY-MM-01_00:00", timestamp())
  time_unit         = "MONTHLY"

  # Cost filters - can be customized
  cost_filter {
    name = "Service"
    values = var.budget_services
  }

  # Alert at 80% of budget (actual spend)
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.notification_emails
    subscriber_sns_topic_arns  = [var.sns_topic_arn]
  }

  # Alert at 100% of budget (actual spend)
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.notification_emails
    subscriber_sns_topic_arns  = [var.sns_topic_arn]
  }

  # Alert at 100% of budget (forecasted spend)
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = var.notification_emails
    subscriber_sns_topic_arns  = [var.sns_topic_arn]
  }

  tags = var.tags
}

# ============================================================================
# AWS Cost Anomaly Detection
# ============================================================================
# Monitors spending patterns and alerts on anomalies using machine learning.
# Detects unusual spending before it becomes a major issue.

resource "aws_ce_anomaly_monitor" "service_monitor" {
  name              = "${var.name_prefix}-cost-anomaly-monitor"
  monitor_type      = "DIMENSIONAL"
  monitor_dimension = "SERVICE"

  tags = var.tags
}

resource "aws_ce_anomaly_subscription" "anomaly_alerts" {
  name      = "${var.name_prefix}-cost-anomaly-alerts"
  frequency = var.anomaly_alert_frequency

  monitor_arn_list = [
    aws_ce_anomaly_monitor.service_monitor.arn
  ]

  subscriber {
    type    = "SNS"
    address = var.sns_topic_arn
  }

  subscriber {
    type    = "EMAIL"
    address = var.notification_emails[0]
  }

  # Alert on anomalies over threshold
  threshold_expression {
    dimension {
      key           = "ANOMALY_TOTAL_IMPACT_ABSOLUTE"
      values        = [tostring(var.anomaly_threshold)]
      match_options = ["GREATER_THAN_OR_EQUAL"]
    }
  }

  tags = var.tags
}

# ============================================================================
# Cost Allocation Tags
# ============================================================================
# Activates cost allocation tags for better cost tracking and reporting.

resource "aws_ce_cost_category" "environment" {
  name         = "Environment"
  rule_version = "CostCategoryExpression.v1"

  rule {
    value = "Production"
    rule {
      dimension {
        key           = "LINKED_ACCOUNT"
        values        = var.production_account_ids
        match_options = ["EQUALS"]
      }
    }
  }

  rule {
    value = "Non-Production"
    rule {
      dimension {
        key           = "LINKED_ACCOUNT"
        values        = var.nonprod_account_ids
        match_options = ["EQUALS"]
      }
    }
  }

  tags = var.tags
}

# ============================================================================
# CloudWatch Dashboard for Cost Monitoring
# ============================================================================
# Creates a dashboard to visualize costs and budget status.

resource "aws_cloudwatch_dashboard" "cost_monitoring" {
  dashboard_name = "${var.name_prefix}-cost-monitoring"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/Billing", "EstimatedCharges", { stat = "Maximum" }]
          ]
          period = 86400
          stat   = "Maximum"
          region = "us-east-1"
          title  = "Estimated Monthly Charges"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/Usage", "ResourceCount", { stat = "Average" }]
          ]
          period = 3600
          stat   = "Average"
          region = var.region
          title  = "Resource Count"
        }
      }
    ]
  })
}

# ============================================================================
# Budget Report
# ============================================================================
# Generates periodic budget reports

resource "aws_budgets_budget" "quarterly" {
  count = var.enable_quarterly_budget ? 1 : 0

  name              = "${var.name_prefix}-quarterly-budget"
  budget_type       = "COST"
  limit_amount      = var.monthly_budget_limit * 3
  limit_unit        = "USD"
  time_period_start = formatdate("YYYY-MM-01_00:00", timestamp())
  time_unit         = "QUARTERLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 90
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.notification_emails
  }

  tags = var.tags
}

# ============================================================================
# Organization Outputs
# ============================================================================

output "organization_id" {
  description = "AWS Organization ID"
  value       = module.control_tower.organization_id
}

output "organization_arn" {
  description = "AWS Organization ARN"
  value       = module.control_tower.organization_arn
}

output "root_id" {
  description = "Root organizational unit ID"
  value       = module.control_tower.root_id
}

output "management_account_id" {
  description = "Management account ID"
  value       = data.aws_caller_identity.current.account_id
}

# ============================================================================
# Organizational Units Outputs
# ============================================================================

output "organizational_units" {
  description = "Map of OU details"
  value = {
    ids  = module.organizational_units.ou_ids
    arns = module.organizational_units.ou_arns
  }
}

output "ou_details" {
  description = "Detailed OU information"
  value = {
    for key, ou in var.organizational_units :
    key => {
      id          = module.organizational_units.ou_ids[key]
      arn         = module.organizational_units.ou_arns[key]
      name        = ou.name
      environment = ou.environment
      policies    = lookup(var.ou_scp_policies, key, [])
    }
  }
}

# ============================================================================
# Service Control Policies Outputs
# ============================================================================

output "scp_policies" {
  description = "Map of SCP policy details"
  value = {
    ids  = module.scp_policies.policy_ids
    arns = module.scp_policies.policy_arns
  }
}

output "scp_attachments" {
  description = "Map of SCP attachment IDs"
  value       = module.scp_attachments.attachment_ids
}

output "root_scp_policies_attached" {
  description = "List of SCPs attached to root OU"
  value       = var.root_scp_policies
}

# ============================================================================
# Control Tower Configuration Outputs
# ============================================================================

output "home_region" {
  description = "Control Tower home region"
  value       = var.home_region
}

output "governed_regions" {
  description = "List of governed regions"
  value       = var.governed_regions
}

output "landing_zone_version" {
  description = "Control Tower landing zone version"
  value       = var.landing_zone_version
}

# ============================================================================
# Monitoring Outputs
# ============================================================================

# ============================================================================
# Monitoring Outputs
# ============================================================================

output "cloudwatch_log_group" {
  description = "CloudWatch Log Group for Control Tower"
  value = {
    name = aws_cloudwatch_log_group.control_tower.name
    arn  = aws_cloudwatch_log_group.control_tower.arn
  }
}

output "sns_topics" {
  description = "SNS topics for notifications"
  value = {
    security = {
      name = aws_sns_topic.security_notifications.name
      arn  = aws_sns_topic.security_notifications.arn
    }
    operational = {
      name = aws_sns_topic.operational_notifications.name
      arn  = aws_sns_topic.operational_notifications.arn
    }
  }
}

output "security_notification_emails" {
  description = "Email addresses subscribed to security notifications"
  value       = var.security_notification_emails
  sensitive   = true
}

output "operational_notification_emails" {
  description = "Email addresses subscribed to operational notifications"
  value       = var.operational_notification_emails
  sensitive   = true
}

# ============================================================================
# Security Outputs
# ============================================================================

output "kms_key" {
  description = "KMS key information"
  value = {
    id    = module.security.kms_key_id
    arn   = module.security.kms_key_arn
    alias = module.security.kms_alias_name
  }
}

output "guardduty" {
  description = "GuardDuty detector information"
  value = {
    detector_id = module.security.guardduty_detector_id
  }
}

output "security_hub" {
  description = "Security Hub information"
  value = {
    account_id = module.security.securityhub_account_id
    standards  = module.security.security_standards
  }
}

output "aws_config" {
  description = "AWS Config information"
  value = {
    recorder_id = module.security.config_recorder_id
    rules       = module.security.config_rules
  }
}

output "access_analyzer" {
  description = "Access Analyzer information"
  value = {
    arn = module.security.access_analyzer_arn
  }
}

output "macie" {
  description = "Macie information (if enabled)"
  value = {
    account_id = module.security.macie_account_id
    enabled    = var.enable_macie
  }
}

# ============================================================================
# Logging Outputs
# ============================================================================

output "logging" {
  description = "Centralized logging information"
  value = {
    log_bucket = {
      id  = module.logging.log_bucket_id
      arn = module.logging.log_bucket_arn
    }
    access_logs_bucket = {
      id = module.logging.access_logs_bucket_id
    }
    cloudtrail = {
      id  = module.logging.cloudtrail_id
      arn = module.logging.cloudtrail_arn
    }
    cloudwatch_log_group = {
      name = module.logging.cloudwatch_log_group_name
      arn  = module.logging.cloudwatch_log_group_arn
    }
    metric_alarms = module.logging.metric_alarms
  }
}

# ============================================================================
# Networking Outputs
# ============================================================================

output "networking" {
  description = "Centralized networking information"
  value = var.enable_centralized_networking ? {
    transit_gateway = {
      id           = module.networking[0].transit_gateway_id
      arn          = module.networking[0].transit_gateway_arn
      route_tables = module.networking[0].transit_gateway_route_tables
    }
    inspection_vpc = {
      id      = module.networking[0].inspection_vpc_id
      cidr    = module.networking[0].inspection_vpc_cidr
      subnets = module.networking[0].inspection_subnets
    }
    network_firewall = {
      id           = module.networking[0].network_firewall_id
      arn          = module.networking[0].network_firewall_arn
      endpoint_ids = module.networking[0].network_firewall_endpoint_ids
    }
    nat_gateways = {
      ids        = module.networking[0].nat_gateway_ids
      public_ips = module.networking[0].nat_gateway_public_ips
    }
    dns_firewall = {
      rule_group_id    = module.networking[0].dns_firewall_rule_group_id
      query_log_config = module.networking[0].dns_query_log_config_id
    }
    cloudwatch_log_groups = module.networking[0].cloudwatch_log_groups
  } : null
}

# ============================================================================
# Deployment Information
# ============================================================================

output "deployment_info" {
  description = "Deployment metadata"
  value = {
    environment  = var.environment
    project_name = var.project_name
    deployed_at  = timestamp()
    deployed_by  = data.aws_caller_identity.current.arn
  }
}

output "next_steps" {
  description = "Post-deployment actions"
  value       = <<-EOT
    Control Tower Landing Zone Deployment Complete!
    
    Next Steps:
    1. Verify Control Tower setup in AWS Console
    2. Configure AWS SSO/Identity Center
    3. Create member accounts in respective OUs
    4. Enable AWS Config, GuardDuty, and Security Hub
    5. Set up CloudTrail organization trail
    6. Review and test SCP policies
    7. Configure account baselines
    8. Set up AWS Backup for account backups
    
    Documentation: See README.md for detailed instructions
  EOT
}

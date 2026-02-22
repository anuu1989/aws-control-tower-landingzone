# ============================================================================
# Account Vending Module - Outputs
# ============================================================================

output "account_ids" {
  description = "Map of account keys to account IDs"
  value = {
    for k, v in aws_organizations_account.accounts :
    k => v.id
  }
}

output "account_arns" {
  description = "Map of account keys to account ARNs"
  value = {
    for k, v in aws_organizations_account.accounts :
    k => v.arn
  }
}

output "account_emails" {
  description = "Map of account keys to account emails"
  value = {
    for k, v in aws_organizations_account.accounts :
    k => v.email
  }
  sensitive = true
}

output "account_details" {
  description = "Detailed information about created accounts"
  value = {
    for k, v in aws_organizations_account.accounts :
    k => {
      id          = v.id
      arn         = v.arn
      name        = v.name
      email       = v.email
      status      = v.status
      joined_date = v.joined_timestamp
      ou_id       = var.accounts[k].ou_id
      environment = var.accounts[k].environment
    }
  }
  sensitive = true
}

output "vpc_ids" {
  description = "Map of account keys to VPC IDs (if bootstrapping enabled)"
  value = var.enable_bootstrapping ? {
    for k, v in module.account_vpc :
    k => v.vpc_id
  } : {}
}

output "vpc_cidrs" {
  description = "Map of account keys to VPC CIDRs"
  value = {
    for k, v in var.accounts :
    k => v.vpc_cidr
  }
}

output "private_subnet_ids" {
  description = "Map of account keys to private subnet IDs (if bootstrapping enabled)"
  value = var.enable_bootstrapping ? {
    for k, v in module.account_vpc :
    k => v.private_subnet_ids
  } : {}
}

output "public_subnet_ids" {
  description = "Map of account keys to public subnet IDs (if bootstrapping enabled)"
  value = var.enable_bootstrapping ? {
    for k, v in module.account_vpc :
    k => v.public_subnet_ids
  } : {}
}

output "security_group_ids" {
  description = "Map of account keys to security group IDs (if bootstrapping enabled)"
  value = var.enable_bootstrapping ? {
    for k, v in module.account_security_groups :
    k => v.security_group_ids
  } : {}
}

output "iam_role_arns" {
  description = "Map of account keys to IAM role ARNs (if bootstrapping enabled)"
  value = var.enable_bootstrapping ? {
    for k, v in module.account_iam :
    k => v.role_arns
  } : {}
}

output "bootstrapped_accounts" {
  description = "List of account keys that were bootstrapped"
  value       = var.enable_bootstrapping ? keys(var.accounts) : []
}

output "account_count" {
  description = "Total number of accounts created"
  value       = length(aws_organizations_account.accounts)
}

output "ssm_parameter_names" {
  description = "SSM parameter names for account inventory"
  value = {
    for k, v in aws_ssm_parameter.account_inventory :
    k => v.name
  }
}

output "policy_ids" {
  description = "Map of policy names to IDs"
  value       = { for k, v in aws_organizations_policy.scp : k => v.id }
}

output "policy_arns" {
  description = "Map of policy names to ARNs"
  value       = { for k, v in aws_organizations_policy.scp : k => v.arn }
}

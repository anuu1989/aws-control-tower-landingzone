output "ou_ids" {
  description = "Map of OU names to IDs"
  value       = { for k, v in aws_organizations_organizational_unit.ou : k => v.id }
}

output "ou_arns" {
  description = "Map of OU names to ARNs"
  value       = { for k, v in aws_organizations_organizational_unit.ou : k => v.arn }
}

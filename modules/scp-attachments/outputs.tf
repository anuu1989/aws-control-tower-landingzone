output "attachment_ids" {
  description = "Map of attachment names to IDs"
  value       = { for k, v in aws_organizations_policy_attachment.attachment : k => v.id }
}

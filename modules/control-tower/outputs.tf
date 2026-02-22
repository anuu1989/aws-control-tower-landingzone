output "organization_id" {
  description = "AWS Organization ID"
  value       = data.aws_organizations_organization.main.id
}

output "organization_arn" {
  description = "AWS Organization ARN"
  value       = data.aws_organizations_organization.main.arn
}

output "root_id" {
  description = "Root organizational unit ID"
  value       = data.aws_organizations_organization.main.roots[0].id
}

output "master_account_id" {
  description = "Master account ID"
  value       = data.aws_organizations_organization.main.master_account_id
}

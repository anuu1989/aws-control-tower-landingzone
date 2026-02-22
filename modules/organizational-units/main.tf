resource "aws_organizations_organizational_unit" "ou" {
  for_each = var.organizational_units

  name      = each.value.name
  parent_id = var.parent_id

  tags = merge(
    {
      Environment = each.value.environment
      ManagedBy   = "Terraform"
    },
    each.value.tags
  )
}

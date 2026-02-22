resource "aws_organizations_policy_attachment" "attachment" {
  for_each = var.policy_attachments

  policy_id = each.value.policy_id
  target_id = each.value.target_id
}

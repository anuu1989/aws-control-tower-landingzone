output "role_arns" {
  description = "Map of role names to ARNs"
  value = merge(
    var.enable_admin_role ? { admin = aws_iam_role.admin[0].arn } : {},
    var.enable_readonly_role ? { readonly = aws_iam_role.readonly[0].arn } : {},
    var.enable_developer_role ? { developer = aws_iam_role.developer[0].arn } : {},
    var.enable_terraform_role ? { terraform = aws_iam_role.terraform[0].arn } : {},
    {
      ec2_instance = aws_iam_role.ec2_instance.arn
      lambda       = aws_iam_role.lambda.arn
    }
  )
}

output "instance_profile_name" {
  description = "EC2 instance profile name"
  value       = aws_iam_instance_profile.ec2.name
}

output "instance_profile_arn" {
  description = "EC2 instance profile ARN"
  value       = aws_iam_instance_profile.ec2.arn
}

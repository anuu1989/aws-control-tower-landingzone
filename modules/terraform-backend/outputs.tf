# ============================================================================
# Terraform Backend Module Outputs
# ============================================================================

output "state_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.id
}

output "state_bucket_arn" {
  description = "ARN of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.arn
}

output "state_bucket_region" {
  description = "Region of the S3 bucket"
  value       = data.aws_region.current.name
}

output "kms_key_id" {
  description = "ID of the KMS key for state encryption"
  value       = aws_kms_key.terraform_state.key_id
}

output "kms_key_arn" {
  description = "ARN of the KMS key for state encryption"
  value       = aws_kms_key.terraform_state.arn
}

output "kms_key_alias" {
  description = "Alias of the KMS key"
  value       = aws_kms_alias.terraform_state.name
}

output "backend_policy_arn" {
  description = "ARN of the IAM policy for backend access"
  value       = var.create_iam_policy ? aws_iam_policy.terraform_backend_access[0].arn : null
}

output "logs_bucket_name" {
  description = "Name of the S3 bucket for access logs"
  value       = var.enable_logging ? aws_s3_bucket.terraform_state_logs[0].id : null
}

output "backend_config" {
  description = "Backend configuration for use in Terraform"
  value = {
    bucket     = aws_s3_bucket.terraform_state.id
    key        = "terraform.tfstate"
    region     = data.aws_region.current.name
    encrypt    = true
    kms_key_id = aws_kms_key.terraform_state.arn
    # Note: use_lockfile = true is the default in Terraform >= 1.6.0
    # No DynamoDB table needed!
  }
}

output "backend_config_hcl" {
  description = "Backend configuration in HCL format"
  value = <<-EOT
    bucket     = "${aws_s3_bucket.terraform_state.id}"
    key        = "terraform.tfstate"
    region     = "${data.aws_region.current.name}"
    encrypt    = true
    kms_key_id = "${aws_kms_key.terraform_state.arn}"
  EOT
}

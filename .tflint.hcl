config {
  module = true
  force = false
}

plugin "aws" {
  enabled = true
  version = "0.29.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

rule "terraform_deprecated_interpolation" {
  enabled = true
}

rule "terraform_deprecated_index" {
  enabled = true
}

rule "terraform_unused_declarations" {
  enabled = true
}

rule "terraform_comment_syntax" {
  enabled = true
}

rule "terraform_documented_outputs" {
  enabled = true
}

rule "terraform_documented_variables" {
  enabled = true
}

rule "terraform_typed_variables" {
  enabled = true
}

rule "terraform_module_pinned_source" {
  enabled = true
}

rule "terraform_naming_convention" {
  enabled = true
}

rule "terraform_required_version" {
  enabled = true
}

rule "terraform_required_providers" {
  enabled = true
}

rule "terraform_standard_module_structure" {
  enabled = true
}

rule "terraform_workspace_remote" {
  enabled = true
}

# AWS-specific rules
rule "aws_resource_missing_tags" {
  enabled = true
  tags = ["Environment", "ManagedBy", "Project"]
}

rule "aws_s3_bucket_versioning_enabled" {
  enabled = true
}

rule "aws_s3_bucket_encryption_enabled" {
  enabled = true
}

rule "aws_cloudtrail_log_file_validation_enabled" {
  enabled = true
}

rule "aws_iam_policy_document_gov_friendly_arns" {
  enabled = true
}

rule "aws_kms_key_rotation_enabled" {
  enabled = true
}

rule "aws_db_instance_backup_retention_period" {
  enabled = true
}

rule "aws_elasticache_replication_group_encryption_at_rest_enabled" {
  enabled = true
}

rule "aws_elasticache_replication_group_encryption_in_transit_enabled" {
  enabled = true
}

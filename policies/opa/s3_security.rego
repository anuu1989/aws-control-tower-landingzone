# OPA S3 Security Policies
package terraform.controltower.s3

import future.keywords.contains
import future.keywords.if
import future.keywords.in
import data.terraform.controltower.helpers

# ============================================================================
# S3 Versioning Policies
# ============================================================================

# POLICY: S3 buckets must have versioning enabled
warn[msg] {
    bucket := helpers.resources_by_type("aws_s3_bucket")[_]
    not has_bucket_versioning(bucket.address)
    msg := sprintf("S3 bucket '%s' should have versioning enabled", [bucket.address])
}

has_bucket_versioning(bucket_address) {
    versioning := helpers.resources_by_type("aws_s3_bucket_versioning")[_]
    contains(versioning.values.bucket, bucket_address)
    versioning.values.versioning_configuration[_].status == "Enabled"
}

# ============================================================================
# S3 Public Access Policies
# ============================================================================

# POLICY: S3 buckets must block public access
deny[msg] {
    bucket := helpers.resources_by_type("aws_s3_bucket")[_]
    not has_public_access_block(bucket.address)
    msg := sprintf("S3 bucket '%s' must have public access blocked", [bucket.address])
}

has_public_access_block(bucket_address) {
    block := helpers.resources_by_type("aws_s3_bucket_public_access_block")[_]
    contains(block.values.bucket, bucket_address)
    block.values.block_public_acls == true
    block.values.block_public_policy == true
    block.values.ignore_public_acls == true
    block.values.restrict_public_buckets == true
}

# ============================================================================
# S3 Logging Policies
# ============================================================================

# POLICY: S3 buckets must have logging enabled
warn[msg] {
    bucket := helpers.resources_by_type("aws_s3_bucket")[_]
    not has_bucket_logging(bucket.address)
    not contains(bucket.address, "access-logs")
    not contains(bucket.address, "log-archive")
    msg := sprintf("S3 bucket '%s' should have access logging enabled", [bucket.address])
}

has_bucket_logging(bucket_address) {
    logging := helpers.resources_by_type("aws_s3_bucket_logging")[_]
    contains(logging.values.bucket, bucket_address)
}

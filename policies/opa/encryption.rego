# OPA Encryption Policies
package terraform.controltower.encryption

import future.keywords.contains
import future.keywords.if
import future.keywords.in
import data.terraform.controltower.helpers

# ============================================================================
# KMS Encryption Policies
# ============================================================================

# POLICY: KMS keys must have rotation enabled
deny[msg] {
    kms_key := helpers.resources_by_type("aws_kms_key")[_]
    not kms_key.values.enable_key_rotation
    msg := sprintf("KMS key '%s' must have automatic key rotation enabled", [kms_key.address])
}

# ============================================================================
# S3 Encryption Policies
# ============================================================================

# POLICY: All S3 buckets must have encryption enabled
deny[msg] {
    bucket := helpers.resources_by_type("aws_s3_bucket")[_]
    not has_bucket_encryption(bucket.address)
    msg := sprintf("S3 bucket '%s' must have encryption enabled", [bucket.address])
}

has_bucket_encryption(bucket_address) {
    encryption := helpers.resources_by_type("aws_s3_bucket_server_side_encryption_configuration")[_]
    contains(encryption.values.bucket, bucket_address)
}

# ============================================================================
# EBS Encryption Policies
# ============================================================================

# POLICY: All EBS volumes must be encrypted
deny[msg] {
    volume := helpers.resources_by_type("aws_ebs_volume")[_]
    not volume.values.encrypted
    msg := sprintf("EBS volume '%s' must be encrypted", [volume.address])
}

# ============================================================================
# RDS Encryption Policies
# ============================================================================

# POLICY: All RDS instances must be encrypted
deny[msg] {
    rds := helpers.resources_by_type("aws_db_instance")[_]
    not rds.values.storage_encrypted
    msg := sprintf("RDS instance '%s' must have storage encryption enabled", [rds.address])
}

# ============================================================================
# ElastiCache Encryption Policies
# ============================================================================

# POLICY: ElastiCache must have encryption at rest
deny[msg] {
    cache := helpers.resources_by_type("aws_elasticache_replication_group")[_]
    not cache.values.at_rest_encryption_enabled
    msg := sprintf("ElastiCache replication group '%s' must have encryption at rest enabled", [cache.address])
}

# POLICY: ElastiCache must have encryption in transit
deny[msg] {
    cache := helpers.resources_by_type("aws_elasticache_replication_group")[_]
    not cache.values.transit_encryption_enabled
    msg := sprintf("ElastiCache replication group '%s' must have encryption in transit enabled", [cache.address])
}

# ============================================================================
# Secrets Manager Encryption Policies
# ============================================================================

# POLICY: Secrets must have KMS encryption
deny[msg] {
    secret := helpers.resources_by_type("aws_secretsmanager_secret")[_]
    not secret.values.kms_key_id
    msg := sprintf("Secrets Manager secret '%s' must use KMS encryption", [secret.address])
}

# POLICY: Secrets must have rotation enabled
warn[msg] {
    secret := helpers.resources_by_type("aws_secretsmanager_secret")[_]
    not has_rotation_config(secret.address)
    msg := sprintf("Secrets Manager secret '%s' should have automatic rotation enabled", [secret.address])
}

has_rotation_config(secret_address) {
    rotation := helpers.resources_by_type("aws_secretsmanager_secret_rotation")[_]
    contains(rotation.values.secret_id, secret_address)
}

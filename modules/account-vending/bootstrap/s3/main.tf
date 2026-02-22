# ============================================================================
# S3 Bootstrap Module
# ============================================================================
# Creates baseline S3 buckets with security configurations
# ============================================================================

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ============================================================================
# Data Sources
# ============================================================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ============================================================================
# Logs Bucket
# ============================================================================
# Bucket for storing application and service logs

resource "aws_s3_bucket" "logs" {
  count = var.create_logs_bucket ? 1 : 0

  bucket = "${var.account_name}-logs-${var.account_id}"

  tags = merge(
    var.tags,
    {
      Name        = "${var.account_name}-logs"
      Environment = var.environment
      Purpose     = "Logs"
      ManagedBy   = "Terraform"
    }
  )
}

resource "aws_s3_bucket_versioning" "logs" {
  count = var.create_logs_bucket ? 1 : 0

  bucket = aws_s3_bucket.logs[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  count = var.create_logs_bucket ? 1 : 0

  bucket = aws_s3_bucket.logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_key_id != null ? "aws:kms" : "AES256"
      kms_master_key_id = var.kms_key_id
    }
    bucket_key_enabled = var.kms_key_id != null ? true : false
  }
}

resource "aws_s3_bucket_public_access_block" "logs" {
  count = var.create_logs_bucket ? 1 : 0

  bucket = aws_s3_bucket.logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  count = var.create_logs_bucket ? 1 : 0

  bucket = aws_s3_bucket.logs[0].id

  rule {
    id     = "transition-and-expire"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = var.logs_retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

resource "aws_s3_bucket_policy" "logs" {
  count = var.create_logs_bucket ? 1 : 0

  bucket = aws_s3_bucket.logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyInsecureTransport"
        Effect = "Deny"
        Principal = "*"
        Action = "s3:*"
        Resource = [
          aws_s3_bucket.logs[0].arn,
          "${aws_s3_bucket.logs[0].arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
      {
        Sid    = "AllowCloudWatchLogs"
        Effect = "Allow"
        Principal = {
          Service = "logs.amazonaws.com"
        }
        Action = [
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.logs[0].arn}/*"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = var.account_id
          }
        }
      }
    ]
  })
}

# ============================================================================
# Backups Bucket
# ============================================================================
# Bucket for storing backups and snapshots

resource "aws_s3_bucket" "backups" {
  count = var.create_backups_bucket ? 1 : 0

  bucket = "${var.account_name}-backups-${var.account_id}"

  tags = merge(
    var.tags,
    {
      Name        = "${var.account_name}-backups"
      Environment = var.environment
      Purpose     = "Backups"
      ManagedBy   = "Terraform"
    }
  )
}

resource "aws_s3_bucket_versioning" "backups" {
  count = var.create_backups_bucket ? 1 : 0

  bucket = aws_s3_bucket.backups[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "backups" {
  count = var.create_backups_bucket ? 1 : 0

  bucket = aws_s3_bucket.backups[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_key_id != null ? "aws:kms" : "AES256"
      kms_master_key_id = var.kms_key_id
    }
    bucket_key_enabled = var.kms_key_id != null ? true : false
  }
}

resource "aws_s3_bucket_public_access_block" "backups" {
  count = var.create_backups_bucket ? 1 : 0

  bucket = aws_s3_bucket.backups[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "backups" {
  count = var.create_backups_bucket ? 1 : 0

  bucket = aws_s3_bucket.backups[0].id

  rule {
    id     = "transition-and-expire"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    transition {
      days          = 180
      storage_class = "DEEP_ARCHIVE"
    }

    expiration {
      days = var.backups_retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

resource "aws_s3_bucket_policy" "backups" {
  count = var.create_backups_bucket ? 1 : 0

  bucket = aws_s3_bucket.backups[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyInsecureTransport"
        Effect = "Deny"
        Principal = "*"
        Action = "s3:*"
        Resource = [
          aws_s3_bucket.backups[0].arn,
          "${aws_s3_bucket.backups[0].arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

# ============================================================================
# Data Bucket (Optional)
# ============================================================================
# Bucket for storing application data

resource "aws_s3_bucket" "data" {
  count = var.create_data_bucket ? 1 : 0

  bucket = "${var.account_name}-data-${var.account_id}"

  tags = merge(
    var.tags,
    {
      Name        = "${var.account_name}-data"
      Environment = var.environment
      Purpose     = "Data"
      ManagedBy   = "Terraform"
    }
  )
}

resource "aws_s3_bucket_versioning" "data" {
  count = var.create_data_bucket ? 1 : 0

  bucket = aws_s3_bucket.data[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data" {
  count = var.create_data_bucket ? 1 : 0

  bucket = aws_s3_bucket.data[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_key_id != null ? "aws:kms" : "AES256"
      kms_master_key_id = var.kms_key_id
    }
    bucket_key_enabled = var.kms_key_id != null ? true : false
  }
}

resource "aws_s3_bucket_public_access_block" "data" {
  count = var.create_data_bucket ? 1 : 0

  bucket = aws_s3_bucket.data[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "data" {
  count = var.create_data_bucket ? 1 : 0

  bucket = aws_s3_bucket.data[0].id

  rule {
    id     = "intelligent-tiering"
    status = "Enabled"

    transition {
      days          = 0
      storage_class = "INTELLIGENT_TIERING"
    }

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

resource "aws_s3_bucket_policy" "data" {
  count = var.create_data_bucket ? 1 : 0

  bucket = aws_s3_bucket.data[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyInsecureTransport"
        Effect = "Deny"
        Principal = "*"
        Action = "s3:*"
        Resource = [
          aws_s3_bucket.data[0].arn,
          "${aws_s3_bucket.data[0].arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

# ============================================================================
# Bucket Logging (Optional)
# ============================================================================
# Enable access logging for all buckets to the logs bucket

resource "aws_s3_bucket_logging" "backups" {
  count = var.create_logs_bucket && var.create_backups_bucket ? 1 : 0

  bucket = aws_s3_bucket.backups[0].id

  target_bucket = aws_s3_bucket.logs[0].id
  target_prefix = "s3-access-logs/backups/"
}

resource "aws_s3_bucket_logging" "data" {
  count = var.create_logs_bucket && var.create_data_bucket ? 1 : 0

  bucket = aws_s3_bucket.data[0].id

  target_bucket = aws_s3_bucket.logs[0].id
  target_prefix = "s3-access-logs/data/"
}

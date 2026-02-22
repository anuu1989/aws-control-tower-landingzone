# ============================================================================
# Terraform Backend Module
# ============================================================================
# Creates S3 bucket for Terraform state with native state locking
# Compatible with Terraform >= 1.6.0 (no DynamoDB required)
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
# KMS Key for S3 Bucket Encryption
# ============================================================================

resource "aws_kms_key" "terraform_state" {
  description             = "KMS key for Terraform state encryption"
  deletion_window_in_days = var.kms_deletion_window
  enable_key_rotation     = true

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-terraform-state-key"
  })
}

resource "aws_kms_alias" "terraform_state" {
  name          = "alias/${var.name_prefix}-terraform-state"
  target_key_id = aws_kms_key.terraform_state.key_id
}

# ============================================================================
# S3 Bucket for Terraform State
# ============================================================================

resource "aws_s3_bucket" "terraform_state" {
  bucket = var.state_bucket_name

  tags = merge(var.tags, {
    Name    = "${var.name_prefix}-terraform-state"
    Purpose = "terraform-state-storage"
  })
}

# Enable versioning
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.terraform_state.arn
    }
    bucket_key_enabled = true
  }
}

# Block all public access
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable logging
resource "aws_s3_bucket_logging" "terraform_state" {
  count = var.enable_logging ? 1 : 0

  bucket = aws_s3_bucket.terraform_state.id

  target_bucket = aws_s3_bucket.terraform_state_logs[0].id
  target_prefix = "state-access-logs/"
}

# Lifecycle policy
resource "aws_s3_bucket_lifecycle_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    id     = "delete-old-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = var.state_retention_days
    }
  }

  rule {
    id     = "transition-old-versions"
    status = "Enabled"

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_transition {
      noncurrent_days = 90
      storage_class   = "GLACIER_IR"
    }

    noncurrent_version_transition {
      noncurrent_days = 180
      storage_class   = "DEEP_ARCHIVE"
    }
  }

  rule {
    id     = "abort-incomplete-multipart-uploads"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# Bucket policy
resource "aws_s3_bucket_policy" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat([
      {
        Sid    = "DenyUnencryptedObjectUploads"
        Effect = "Deny"
        Principal = "*"
        Action = "s3:PutObject"
        Resource = "${aws_s3_bucket.terraform_state.arn}/*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = "aws:kms"
          }
        }
      },
      {
        Sid    = "DenyInsecureTransport"
        Effect = "Deny"
        Principal = "*"
        Action = "s3:*"
        Resource = [
          aws_s3_bucket.terraform_state.arn,
          "${aws_s3_bucket.terraform_state.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ],
    length(var.allowed_principals) > 0 ? [
      {
        Sid    = "AllowTerraformAccess"
        Effect = "Allow"
        Principal = {
          AWS = var.allowed_principals
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketVersioning"
        ]
        Resource = [
          aws_s3_bucket.terraform_state.arn,
          "${aws_s3_bucket.terraform_state.arn}/*"
        ]
      }
    ] : [])
  })
}

# ============================================================================
# S3 Bucket for Access Logs (Optional)
# ============================================================================

resource "aws_s3_bucket" "terraform_state_logs" {
  count = var.enable_logging ? 1 : 0

  bucket = "${var.state_bucket_name}-logs"

  tags = merge(var.tags, {
    Name    = "${var.name_prefix}-terraform-state-logs"
    Purpose = "terraform-state-access-logs"
  })
}

resource "aws_s3_bucket_versioning" "terraform_state_logs" {
  count = var.enable_logging ? 1 : 0

  bucket = aws_s3_bucket.terraform_state_logs[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_logs" {
  count = var.enable_logging ? 1 : 0

  bucket = aws_s3_bucket.terraform_state_logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.terraform_state.arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state_logs" {
  count = var.enable_logging ? 1 : 0

  bucket = aws_s3_bucket.terraform_state_logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "terraform_state_logs" {
  count = var.enable_logging ? 1 : 0

  bucket = aws_s3_bucket.terraform_state_logs[0].id

  rule {
    id     = "delete-old-logs"
    status = "Enabled"

    expiration {
      days = var.logs_retention_days
    }
  }

  rule {
    id     = "transition-logs"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER_IR"
    }
  }
}

# ============================================================================
# CloudWatch Alarms for Monitoring (Optional)
# ============================================================================

resource "aws_cloudwatch_metric_alarm" "state_bucket_size" {
  count = var.enable_monitoring ? 1 : 0

  alarm_name          = "${var.name_prefix}-state-bucket-size"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "BucketSizeBytes"
  namespace           = "AWS/S3"
  period              = "86400"
  statistic           = "Average"
  threshold           = var.state_bucket_size_threshold
  alarm_description   = "Alert when state bucket size exceeds threshold"
  alarm_actions       = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []

  dimensions = {
    BucketName  = aws_s3_bucket.terraform_state.id
    StorageType = "StandardStorage"
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "state_bucket_objects" {
  count = var.enable_monitoring ? 1 : 0

  alarm_name          = "${var.name_prefix}-state-bucket-objects"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "NumberOfObjects"
  namespace           = "AWS/S3"
  period              = "86400"
  statistic           = "Average"
  threshold           = 1000
  alarm_description   = "Alert when state bucket has too many objects"
  alarm_actions       = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []

  dimensions = {
    BucketName  = aws_s3_bucket.terraform_state.id
    StorageType = "AllStorageTypes"
  }

  tags = var.tags
}

# ============================================================================
# EventBridge Rule for State Changes (Optional)
# ============================================================================

resource "aws_cloudwatch_event_rule" "state_changes" {
  count = var.enable_monitoring ? 1 : 0

  name        = "${var.name_prefix}-terraform-state-changes"
  description = "Capture Terraform state file changes"

  event_pattern = jsonencode({
    source      = ["aws.s3"]
    detail-type = ["Object Created", "Object Deleted"]
    detail = {
      bucket = {
        name = [aws_s3_bucket.terraform_state.id]
      }
    }
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "state_changes" {
  count = var.enable_monitoring && var.alarm_sns_topic_arn != "" ? 1 : 0

  rule      = aws_cloudwatch_event_rule.state_changes[0].name
  target_id = "SendToSNS"
  arn       = var.alarm_sns_topic_arn
}

# ============================================================================
# IAM Policy for Terraform Backend Access
# ============================================================================

resource "aws_iam_policy" "terraform_backend_access" {
  count = var.create_iam_policy ? 1 : 0

  name        = "${var.name_prefix}-terraform-backend-access"
  description = "Policy for accessing Terraform backend resources"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3StateAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketVersioning",
          "s3:GetObjectVersion",
          "s3:ListBucketVersions"
        ]
        Resource = [
          aws_s3_bucket.terraform_state.arn,
          "${aws_s3_bucket.terraform_state.arn}/*"
        ]
      },
      {
        Sid    = "KMSAccess"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:DescribeKey",
          "kms:GenerateDataKey"
        ]
        Resource = aws_kms_key.terraform_state.arn
      }
    ]
  })

  tags = var.tags
}

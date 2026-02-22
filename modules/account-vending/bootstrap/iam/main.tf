# ============================================================================
# IAM Bootstrap Module
# ============================================================================
# Creates baseline IAM roles for cross-account access and common use cases

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
# Admin Role
# ============================================================================

resource "aws_iam_role" "admin" {
  count = var.enable_admin_role ? 1 : 0

  name        = "${var.account_name}-AdminRole"
  description = "Administrative access role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.management_account_id}:root"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = var.account_id
          }
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name        = "${var.account_name}-AdminRole"
      Environment = var.environment
      Purpose     = "Administrative Access"
    }
  )
}

resource "aws_iam_role_policy_attachment" "admin" {
  count = var.enable_admin_role ? 1 : 0

  role       = aws_iam_role.admin[0].name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# ============================================================================
# ReadOnly Role
# ============================================================================

resource "aws_iam_role" "readonly" {
  count = var.enable_readonly_role ? 1 : 0

  name        = "${var.account_name}-ReadOnlyRole"
  description = "Read-only access role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.management_account_id}:root"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = var.account_id
          }
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name        = "${var.account_name}-ReadOnlyRole"
      Environment = var.environment
      Purpose     = "Read-Only Access"
    }
  )
}

resource "aws_iam_role_policy_attachment" "readonly" {
  count = var.enable_readonly_role ? 1 : 0

  role       = aws_iam_role.readonly[0].name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# ============================================================================
# Developer Role
# ============================================================================

resource "aws_iam_role" "developer" {
  count = var.enable_developer_role ? 1 : 0

  name        = "${var.account_name}-DeveloperRole"
  description = "Developer access role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.management_account_id}:root"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = var.account_id
          }
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name        = "${var.account_name}-DeveloperRole"
      Environment = var.environment
      Purpose     = "Developer Access"
    }
  )
}

resource "aws_iam_role_policy" "developer" {
  count = var.enable_developer_role ? 1 : 0

  name = "${var.account_name}-DeveloperPolicy"
  role = aws_iam_role.developer[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:*",
          "s3:*",
          "lambda:*",
          "dynamodb:*",
          "rds:*",
          "cloudwatch:*",
          "logs:*",
          "sns:*",
          "sqs:*",
          "elasticache:*",
          "es:*",
          "ecr:*",
          "ecs:*",
          "eks:*"
        ]
        Resource = "*"
      },
      {
        Effect = "Deny"
        Action = [
          "iam:*",
          "organizations:*",
          "account:*"
        ]
        Resource = "*"
      }
    ]
  })
}

# ============================================================================
# Terraform Role
# ============================================================================

resource "aws_iam_role" "terraform" {
  count = var.enable_terraform_role ? 1 : 0

  name        = "${var.account_name}-TerraformRole"
  description = "Terraform automation role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.management_account_id}:root"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = var.account_id
          }
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name        = "${var.account_name}-TerraformRole"
      Environment = var.environment
      Purpose     = "Infrastructure Automation"
    }
  )
}

resource "aws_iam_role_policy_attachment" "terraform" {
  count = var.enable_terraform_role ? 1 : 0

  role       = aws_iam_role.terraform[0].name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# ============================================================================
# EC2 Instance Profile Role
# ============================================================================

resource "aws_iam_role" "ec2_instance" {
  name        = "${var.account_name}-EC2InstanceRole"
  description = "Default role for EC2 instances"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name        = "${var.account_name}-EC2InstanceRole"
      Environment = var.environment
      Purpose     = "EC2 Instance Profile"
    }
  )
}

resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ec2_cloudwatch" {
  role       = aws_iam_role.ec2_instance.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.account_name}-EC2InstanceProfile"
  role = aws_iam_role.ec2_instance.name

  tags = var.tags
}

# ============================================================================
# Lambda Execution Role
# ============================================================================

resource "aws_iam_role" "lambda" {
  name        = "${var.account_name}-LambdaExecutionRole"
  description = "Default role for Lambda functions"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name        = "${var.account_name}-LambdaExecutionRole"
      Environment = var.environment
      Purpose     = "Lambda Execution"
    }
  )
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# ============================================================================
# Security Groups Bootstrap Module
# ============================================================================
# Creates baseline security groups for common use cases

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
# SSH Security Group
# ============================================================================

resource "aws_security_group" "ssh" {
  name        = "${var.account_name}-ssh-sg"
  description = "Allow SSH access from specified CIDRs"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from allowed CIDRs"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidrs
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.account_name}-ssh-sg"
      Environment = var.environment
      Purpose     = "SSH Access"
    }
  )
}

# ============================================================================
# HTTPS Security Group
# ============================================================================

resource "aws_security_group" "https" {
  name        = "${var.account_name}-https-sg"
  description = "Allow HTTPS access from specified CIDRs"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTPS from allowed CIDRs"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_https_cidrs
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.account_name}-https-sg"
      Environment = var.environment
      Purpose     = "HTTPS Access"
    }
  )
}

# ============================================================================
# HTTP Security Group
# ============================================================================

resource "aws_security_group" "http" {
  name        = "${var.account_name}-http-sg"
  description = "Allow HTTP access from specified CIDRs"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from allowed CIDRs"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_https_cidrs
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.account_name}-http-sg"
      Environment = var.environment
      Purpose     = "HTTP Access"
    }
  )
}

# ============================================================================
# Internal Communication Security Group
# ============================================================================

resource "aws_security_group" "internal" {
  name        = "${var.account_name}-internal-sg"
  description = "Allow internal VPC communication"
  vpc_id      = var.vpc_id

  ingress {
    description = "All traffic from VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.account_name}-internal-sg"
      Environment = var.environment
      Purpose     = "Internal Communication"
    }
  )
}

# ============================================================================
# Database Security Group
# ============================================================================

resource "aws_security_group" "database" {
  name        = "${var.account_name}-database-sg"
  description = "Allow database access from internal VPC"
  vpc_id      = var.vpc_id

  ingress {
    description = "MySQL/Aurora from VPC"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "PostgreSQL from VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.account_name}-database-sg"
      Environment = var.environment
      Purpose     = "Database Access"
    }
  )
}

# ============================================================================
# Application Load Balancer Security Group
# ============================================================================

resource "aws_security_group" "alb" {
  name        = "${var.account_name}-alb-sg"
  description = "Allow HTTP/HTTPS access to ALB"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.account_name}-alb-sg"
      Environment = var.environment
      Purpose     = "Application Load Balancer"
    }
  )
}

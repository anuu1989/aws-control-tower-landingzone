terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend configuration for state storage
  # Terraform 1.6+ uses native S3 state locking (no DynamoDB required!)
  # Deploy backend module first: cd examples/terraform-backend && terraform apply
  # Then initialize with: terraform init -backend-config=backend.hcl
  # Or uncomment and configure inline:
  # backend "s3" {
  #   bucket     = "your-org-control-tower-terraform-state"
  #   key        = "control-tower/terraform.tfstate"
  #   region     = "ap-southeast-2"
  #   encrypt    = true
  #   kms_key_id = "arn:aws:kms:ap-southeast-2:123456789012:key/12345678-1234-1234-1234-123456789012"
  # }
}

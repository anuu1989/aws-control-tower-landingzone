terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Control Tower Landing Zone
resource "aws_controltower_landing_zone" "main" {
  manifest_json = jsonencode({
    governedRegions = var.governed_regions
    organizationStructure = {
      security = {
        name = "Security"
      }
      sandbox = {
        name = "Sandbox"
      }
    }
  })
  version = var.landing_zone_version
}

# Organization
data "aws_organizations_organization" "main" {}

# Root OU
data "aws_organizations_organizational_units" "root" {
  parent_id = data.aws_organizations_organization.main.roots[0].id
}

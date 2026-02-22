locals {
  # Define all SCP policies
  policies = {
    # ========================================================================
    # Core Security Policies
    # ========================================================================

    deny_root_user = {
      name        = "DenyRootUserAccess"
      description = "Deny all actions by root user"
      content = {
        Version = "2012-10-17"
        Statement = [
          {
            Sid    = "DenyRootUser"
            Effect = "Deny"
            Action = "*"
            Resource = "*"
            Condition = {
              StringLike = {
                "aws:PrincipalArn" = "arn:aws:iam::*:root"
              }
            }
          }
        ]
      }
    }

    require_mfa = {
      name        = "RequireMFA"
      description = "Require MFA for all API calls except MFA management"
      content = {
        Version = "2012-10-17"
        Statement = [
          {
            Sid    = "DenyAllExceptListedIfNoMFA"
            Effect = "Deny"
            NotAction = [
              "iam:CreateVirtualMFADevice",
              "iam:EnableMFADevice",
              "iam:GetUser",
              "iam:ListMFADevices",
              "iam:ListVirtualMFADevices",
              "iam:ResyncMFADevice",
              "sts:GetSessionToken"
            ]
            Resource = "*"
            Condition = {
              BoolIfExists = {
                "aws:MultiFactorAuthPresent" = "false"
              }
            }
          }
        ]
      }
    }

    restrict_regions = {
      name        = "RestrictRegions"
      description = "Restrict operations to allowed regions only"
      content = {
        Version = "2012-10-17"
        Statement = [
          {
            Sid    = "DenyAllOutsideAllowedRegions"
            Effect = "Deny"
            NotAction = [
              "a4b:*",
              "acm:*",
              "aws-marketplace-management:*",
              "aws-marketplace:*",
              "aws-portal:*",
              "budgets:*",
              "ce:*",
              "chime:*",
              "cloudfront:*",
              "config:*",
              "cur:*",
              "directconnect:*",
              "ec2:DescribeRegions",
              "ec2:DescribeTransitGateways",
              "ec2:DescribeVpnGateways",
              "fms:*",
              "globalaccelerator:*",
              "health:*",
              "iam:*",
              "importexport:*",
              "kms:*",
              "mobileanalytics:*",
              "networkmanager:*",
              "organizations:*",
              "pricing:*",
              "route53:*",
              "route53domains:*",
              "s3:GetAccountPublic*",
              "s3:ListAllMyBuckets",
              "s3:PutAccountPublic*",
              "shield:*",
              "sts:*",
              "support:*",
              "trustedadvisor:*",
              "waf-regional:*",
              "waf:*",
              "wafv2:*",
              "wellarchitected:*"
            ]
            Resource = "*"
            Condition = {
              StringNotEquals = {
                "aws:RequestedRegion" = var.allowed_regions
              }
            }
          }
        ]
      }
    }

    deny_leave_org = {
      name        = "DenyLeaveOrganization"
      description = "Prevent accounts from leaving the organization"
      content = {
        Version = "2012-10-17"
        Statement = [
          {
            Sid      = "DenyLeaveOrganization"
            Effect   = "Deny"
            Action   = "organizations:LeaveOrganization"
            Resource = "*"
          }
        ]
      }
    }

    # ========================================================================
    # Logging and Monitoring Protection
    # ========================================================================

    protect_cloudtrail = {
      name        = "ProtectCloudTrail"
      description = "Prevent disabling or deleting CloudTrail"
      content = {
        Version = "2012-10-17"
        Statement = [
          {
            Sid    = "ProtectCloudTrail"
            Effect = "Deny"
            Action = [
              "cloudtrail:DeleteTrail",
              "cloudtrail:StopLogging",
              "cloudtrail:UpdateTrail"
            ]
            Resource = "*"
          }
        ]
      }
    }

    protect_security_services = {
      name        = "ProtectSecurityServices"
      description = "Prevent disabling security services"
      content = {
        Version = "2012-10-17"
        Statement = [
          {
            Sid    = "ProtectSecurityServices"
            Effect = "Deny"
            Action = [
              "config:DeleteConfigRule",
              "config:DeleteConfigurationRecorder",
              "config:DeleteDeliveryChannel",
              "config:StopConfigurationRecorder",
              "guardduty:DeleteDetector",
              "guardduty:DeleteMembers",
              "guardduty:DisassociateFromMasterAccount",
              "guardduty:DisassociateMembers",
              "guardduty:StopMonitoringMembers",
              "securityhub:DeleteInvitations",
              "securityhub:DisableSecurityHub",
              "securityhub:DisassociateFromMasterAccount",
              "securityhub:DeleteMembers",
              "securityhub:DisassociateMembers",
              "access-analyzer:DeleteAnalyzer"
            ]
            Resource = "*"
          }
        ]
      }
    }

    # ========================================================================
    # Encryption Requirements
    # ========================================================================

    require_encryption = {
      name        = "RequireEncryption"
      description = "Require encryption for S3 and EBS"
      content = {
        Version = "2012-10-17"
        Statement = [
          {
            Sid    = "DenyUnencryptedS3Uploads"
            Effect = "Deny"
            Action = "s3:PutObject"
            Resource = "*"
            Condition = {
              StringNotEquals = {
                "s3:x-amz-server-side-encryption" = [
                  "AES256",
                  "aws:kms"
                ]
              }
            }
          },
          {
            Sid    = "DenyUnencryptedEBSVolumes"
            Effect = "Deny"
            Action = [
              "ec2:CreateVolume",
              "ec2:RunInstances"
            ]
            Resource = "arn:aws:ec2:*:*:volume/*"
            Condition = {
              Bool = {
                "ec2:Encrypted" = "false"
              }
            }
          }
        ]
      }
    }

    deny_unencrypted_rds = {
      name        = "DenyUnencryptedRDS"
      description = "Require encryption for RDS databases"
      content = {
        Version = "2012-10-17"
        Statement = [
          {
            Sid    = "DenyUnencryptedRDSInstances"
            Effect = "Deny"
            Action = [
              "rds:CreateDBInstance",
              "rds:CreateDBCluster"
            ]
            Resource = "*"
            Condition = {
              Bool = {
                "rds:StorageEncrypted" = "false"
              }
            }
          }
        ]
      }
    }

    deny_unencrypted_snapshots = {
      name        = "DenyUnencryptedSnapshots"
      description = "Require encryption for EBS snapshots"
      content = {
        Version = "2012-10-17"
        Statement = [
          {
            Sid    = "DenyUnencryptedSnapshots"
            Effect = "Deny"
            Action = "ec2:CreateSnapshot"
            Resource = "*"
            Condition = {
              Bool = {
                "ec2:Encrypted" = "false"
              }
            }
          }
        ]
      }
    }

    require_kms_encryption = {
      name        = "RequireKMSEncryption"
      description = "Require KMS encryption for supported services"
      content = {
        Version = "2012-10-17"
        Statement = [
          {
            Sid    = "RequireKMSForEFS"
            Effect = "Deny"
            Action = "elasticfilesystem:CreateFileSystem"
            Resource = "*"
            Condition = {
              Bool = {
                "elasticfilesystem:Encrypted" = "false"
              }
            }
          },
          {
            Sid    = "RequireKMSForDynamoDB"
            Effect = "Deny"
            Action = [
              "dynamodb:CreateTable",
              "dynamodb:CreateGlobalTable"
            ]
            Resource = "*"
            Condition = {
              StringNotEquals = {
                "dynamodb:EncryptionType" = "KMS"
              }
            }
          }
        ]
      }
    }

    deny_unencrypted_secrets = {
      name        = "DenyUnencryptedSecrets"
      description = "Require encryption for Secrets Manager"
      content = {
        Version = "2012-10-17"
        Statement = [
          {
            Sid    = "RequireKMSForSecrets"
            Effect = "Deny"
            Action = "secretsmanager:CreateSecret"
            Resource = "*"
            Condition = {
              "Null" = {
                "secretsmanager:KmsKeyId" = "true"
              }
            }
          }
        ]
      }
    }

    deny_unencrypted_elasticache = {
      name        = "DenyUnencryptedElastiCache"
      description = "Require encryption for ElastiCache"
      content = {
        Version = "2012-10-17"
        Statement = [
          {
            Sid    = "RequireElastiCacheEncryption"
            Effect = "Deny"
            Action = [
              "elasticache:CreateReplicationGroup",
              "elasticache:CreateCacheCluster"
            ]
            Resource = "*"
            Condition = {
              Bool = {
                "elasticache:AtRestEncryptionEnabled" = "false"
              }
            }
          },
          {
            Sid    = "RequireElastiCacheTransitEncryption"
            Effect = "Deny"
            Action = [
              "elasticache:CreateReplicationGroup",
              "elasticache:CreateCacheCluster"
            ]
            Resource = "*"
            Condition = {
              Bool = {
                "elasticache:TransitEncryptionEnabled" = "false"
              }
            }
          }
        ]
      }
    }

    # ========================================================================
    # S3 Security Policies
    # ========================================================================

    deny_public_s3 = {
      name        = "DenyPublicS3"
      description = "Prevent public S3 buckets"
      content = {
        Version = "2012-10-17"
        Statement = [
          {
            Sid    = "DenyPublicS3BlockSettings"
            Effect = "Deny"
            Action = [
              "s3:PutBucketPublicAccessBlock",
              "s3:PutAccountPublicAccessBlock"
            ]
            Resource = "*"
            Condition = {
              Bool = {
                "s3:BlockPublicAcls"       = "false"
                "s3:BlockPublicPolicy"     = "false"
                "s3:IgnorePublicAcls"      = "false"
                "s3:RestrictPublicBuckets" = "false"
              }
            }
          }
        ]
      }
    }

    deny_s3_public_access = {
      name        = "DenyS3PublicAccess"
      description = "Prevent S3 buckets from being made public"
      content = {
        Version = "2012-10-17"
        Statement = [
          {
            Sid    = "DenyS3PublicACL"
            Effect = "Deny"
            Action = [
              "s3:PutBucketPolicy",
              "s3:PutBucketAcl",
              "s3:PutObjectAcl"
            ]
            Resource = "*"
            Condition = {
              StringEquals = {
                "s3:x-amz-acl" = [
                  "public-read",
                  "public-read-write",
                  "authenticated-read"
                ]
              }
            }
          }
        ]
      }
    }

    require_s3_ssl = {
      name        = "RequireS3SSL"
      description = "Require SSL/TLS for S3 access"
      content = {
        Version = "2012-10-17"
        Statement = [
          {
            Sid    = "DenyInsecureS3Access"
            Effect = "Deny"
            Action = "s3:*"
            Resource = "*"
            Condition = {
              Bool = {
                "aws:SecureTransport" = "false"
              }
            }
          }
        ]
      }
    }

    require_s3_versioning = {
      name        = "RequireS3Versioning"
      description = "Require versioning for S3 buckets"
      content = {
        Version = "2012-10-17"
        Statement = [
          {
            Sid    = "DenyS3WithoutVersioning"
            Effect = "Deny"
            Action = "s3:CreateBucket"
            Resource = "*"
          }
        ]
      }
    }

    # ========================================================================
    # EC2 Security Policies
    # ========================================================================

    restrict_instance_types = {
      name        = "RestrictInstanceTypes"
      description = "Limit EC2 instance types"
      content = {
        Version = "2012-10-17"
        Statement = [
          {
            Sid    = "RestrictInstanceTypes"
            Effect = "Deny"
            Action = [
              "ec2:RunInstances",
              "ec2:StartInstances"
            ]
            Resource = "arn:aws:ec2:*:*:instance/*"
            Condition = {
              StringNotLike = {
                "ec2:InstanceType" = var.allowed_instance_types
              }
            }
          }
        ]
      }
    }

    require_imdsv2 = {
      name        = "RequireIMDSv2"
      description = "Require IMDSv2 for EC2 instances"
      content = {
        Version = "2012-10-17"
        Statement = [
          {
            Sid    = "RequireIMDSv2"
            Effect = "Deny"
            Action = "ec2:RunInstances"
            Resource = "arn:aws:ec2:*:*:instance/*"
            Condition = {
              StringNotEquals = {
                "ec2:MetadataHttpTokens" = "required"
              }
            }
          }
        ]
      }
    }

    deny_public_ami = {
      name        = "DenyPublicAMI"
      description = "Prevent sharing AMIs publicly"
      content = {
        Version = "2012-10-17"
        Statement = [
          {
            Sid    = "DenyPublicAMI"
            Effect = "Deny"
            Action = [
              "ec2:ModifyImageAttribute",
              "ec2:ModifySnapshotAttribute"
            ]
            Resource = "*"
            Condition = {
              StringEquals = {
                "ec2:Add/group" = "all"
              }
            }
          }
        ]
      }
    }

    restrict_ec2_termination = {
      name        = "RestrictEC2Termination"
      description = "Require termination protection for production instances"
      content = {
        Version = "2012-10-17"
        Statement = [
          {
            Sid    = "RequireTerminationProtection"
            Effect = "Deny"
            Action = "ec2:RunInstances"
            Resource = "arn:aws:ec2:*:*:instance/*"
            Condition = {
              StringNotEquals = {
                "ec2:DisableApiTermination" = "true"
              }
            }
          }
        ]
      }
    }

    # ========================================================================
    # Network Security Policies
    # ========================================================================

    deny_vpc_internet_gateway_unauthorized = {
      name        = "DenyUnauthorizedIGW"
      description = "Prevent unauthorized Internet Gateway creation"
      content = {
        Version = "2012-10-17"
        Statement = [
          {
            Sid    = "DenyIGWCreation"
            Effect = "Deny"
            Action = [
              "ec2:CreateInternetGateway",
              "ec2:AttachInternetGateway"
            ]
            Resource = "*"
          }
        ]
      }
    }

    require_vpc_flow_logs = {
      name        = "RequireVPCFlowLogs"
      description = "Require VPC Flow Logs for all VPCs"
      content = {
        Version = "2012-10-17"
        Statement = [
          {
            Sid    = "DenyVPCWithoutFlowLogs"
            Effect = "Deny"
            Action = "ec2:CreateVpc"
            Resource = "*"
          }
        ]
      }
    }

    deny_default_vpc = {
      name        = "DenyDefaultVPC"
      description = "Prevent use of default VPC"
      content = {
        Version = "2012-10-17"
        Statement = [
          {
            Sid    = "DenyDefaultVPCUsage"
            Effect = "Deny"
            Action = [
              "ec2:RunInstances",
              "rds:CreateDBInstance",
              "elasticloadbalancing:CreateLoadBalancer"
            ]
            Resource = "*"
          }
        ]
      }
    }

    # ========================================================================
    # IAM Security Policies
    # ========================================================================

    deny_iam_user_creation = {
      name        = "DenyIAMUserCreation"
      description = "Prevent creation of IAM users (use SSO instead)"
      content = {
        Version = "2012-10-17"
        Statement = [
          {
            Sid    = "DenyIAMUserCreation"
            Effect = "Deny"
            Action = [
              "iam:CreateUser",
              "iam:CreateAccessKey"
            ]
            Resource = "*"
          }
        ]
      }
    }

    require_iam_password_policy = {
      name        = "RequireIAMPasswordPolicy"
      description = "Enforce strong IAM password policy"
      content = {
        Version = "2012-10-17"
        Statement = [
          {
            Sid    = "DenyWeakPasswordPolicy"
            Effect = "Deny"
            Action = "iam:UpdateAccountPasswordPolicy"
            Resource = "*"
            Condition = {
              NumericLessThan = {
                "iam:MinimumPasswordLength" = "14"
              }
            }
          }
        ]
      }
    }

    deny_iam_policy_changes = {
      name        = "DenyIAMPolicyChanges"
      description = "Restrict IAM policy modifications"
      content = {
        Version = "2012-10-17"
        Statement = [
          {
            Sid    = "DenyIAMPolicyChanges"
            Effect = "Deny"
            Action = [
              "iam:CreatePolicyVersion",
              "iam:DeletePolicy",
              "iam:DeletePolicyVersion",
              "iam:SetDefaultPolicyVersion"
            ]
            Resource = "*"
            Condition = {
              StringNotLike = {
                "aws:PrincipalArn" = "arn:aws:iam::*:role/Admin*"
              }
            }
          }
        ]
      }
    }

    # ========================================================================
    # KMS Security Policies
    # ========================================================================

    deny_kms_key_deletion = {
      name        = "DenyKMSKeyDeletion"
      description = "Prevent immediate KMS key deletion"
      content = {
        Version = "2012-10-17"
        Statement = [
          {
            Sid    = "DenyKMSKeyDeletion"
            Effect = "Deny"
            Action = [
              "kms:ScheduleKeyDeletion",
              "kms:DeleteAlias"
            ]
            Resource = "*"
          }
        ]
      }
    }

    # ========================================================================
    # Database Security Policies
    # ========================================================================

    deny_public_rds = {
      name        = "DenyPublicRDS"
      description = "Prevent publicly accessible RDS instances"
      content = {
        Version = "2012-10-17"
        Statement = [
          {
            Sid    = "DenyPublicRDS"
            Effect = "Deny"
            Action = [
              "rds:CreateDBInstance",
              "rds:ModifyDBInstance"
            ]
            Resource = "*"
            Condition = {
              Bool = {
                "rds:PubliclyAccessible" = "true"
              }
            }
          }
        ]
      }
    }

    require_rds_backup = {
      name        = "RequireRDSBackup"
      description = "Require automated backups for RDS"
      content = {
        Version = "2012-10-17"
        Statement = [
          {
            Sid    = "RequireRDSBackup"
            Effect = "Deny"
            Action = "rds:CreateDBInstance"
            Resource = "*"
            Condition = {
              NumericLessThan = {
                "rds:BackupRetentionPeriod" = "7"
              }
            }
          }
        ]
      }
    }

    require_rds_multi_az = {
      name        = "RequireRDSMultiAZ"
      description = "Require Multi-AZ for production RDS"
      content = {
        Version = "2012-10-17"
        Statement = [
          {
            Sid    = "RequireMultiAZ"
            Effect = "Deny"
            Action = "rds:CreateDBInstance"
            Resource = "*"
            Condition = {
              Bool = {
                "rds:MultiAz" = "false"
              }
            }
          }
        ]
      }
    }

    deny_public_redshift = {
      name        = "DenyPublicRedshift"
      description = "Prevent publicly accessible Redshift clusters"
      content = {
        Version = "2012-10-17"
        Statement = [
          {
            Sid    = "DenyPublicRedshift"
            Effect = "Deny"
            Action = [
              "redshift:CreateCluster",
              "redshift:ModifyCluster"
            ]
            Resource = "*"
            Condition = {
              Bool = {
                "redshift:PubliclyAccessible" = "true"
              }
            }
          }
        ]
      }
    }

    # ========================================================================
    # Additional Service Policies
    # ========================================================================

    restrict_lambda_vpc = {
      name        = "RestrictLambdaVPC"
      description = "Require Lambda functions to run in VPC"
      content = {
        Version = "2012-10-17"
        Statement = [
          {
            Sid    = "RequireLambdaInVPC"
            Effect = "Deny"
            Action = [
              "lambda:CreateFunction",
              "lambda:UpdateFunctionConfiguration"
            ]
            Resource = "*"
            Condition = {
              "Null" = {
                "lambda:VpcIds" = "true"
              }
            }
          }
        ]
      }
    }

    require_elb_logging = {
      name        = "RequireELBLogging"
      description = "Require access logging for load balancers"
      content = {
        Version = "2012-10-17"
        Statement = [
          {
            Sid    = "RequireALBLogging"
            Effect = "Deny"
            Action = [
              "elasticloadbalancing:CreateLoadBalancer",
              "elasticloadbalancing:ModifyLoadBalancerAttributes"
            ]
            Resource = "*"
          }
        ]
      }
    }

    restrict_resource_deletion = {
      name        = "RestrictResourceDeletion"
      description = "Prevent deletion of critical resources"
      content = {
        Version = "2012-10-17"
        Statement = [
          {
            Sid    = "DenyResourceDeletion"
            Effect = "Deny"
            Action = [
              "ec2:DeleteVpc",
              "ec2:DeleteSubnet",
              "ec2:DeleteRouteTable",
              "rds:DeleteDBInstance",
              "s3:DeleteBucket",
              "dynamodb:DeleteTable"
            ]
            Resource = "*"
            Condition = {
              StringNotLike = {
                "aws:PrincipalArn" = "arn:aws:iam::*:role/Admin*"
              }
            }
          }
        ]
      }
    }

    require_tagging = {
      name        = "RequireTagging"
      description = "Require specific tags on resources"
      content = {
        Version = "2012-10-17"
        Statement = [
          {
            Sid    = "RequireTags"
            Effect = "Deny"
            Action = [
              "ec2:RunInstances",
              "ec2:CreateVolume",
              "rds:CreateDBInstance",
              "s3:CreateBucket"
            ]
            Resource = "*"
            Condition = {
              "Null" = {
                "aws:RequestTag/Environment" = "true"
              }
            }
          }
        ]
      }
    }
  }

  # Filter policies based on enabled list
  enabled_policies = {
    for k, v in local.policies : k => v
    if contains(var.enabled_policies, k)
  }
}

# Create SCP policies
resource "aws_organizations_policy" "scp" {
  for_each = local.enabled_policies

  name        = each.value.name
  description = each.value.description
  type        = "SERVICE_CONTROL_POLICY"
  content     = jsonencode(each.value.content)
}

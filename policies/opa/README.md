# OPA Policies - Modular Structure

Modular OPA policy organization for AWS Control Tower Landing Zone validation.

## Structure

```
policies/opa/
├── README.md                    # This file
├── main.rego                    # Policy aggregator (imports all modules)
├── helpers.rego                 # Shared helper functions
│
├── encryption.rego              # Encryption policies (KMS, S3, EBS, RDS, ElastiCache, Secrets)
├── encryption_test.rego         # Encryption policy tests
│
├── s3_security.rego             # S3 security policies (versioning, public access, logging)
├── s3_security_test.rego        # S3 security tests
│
├── ec2_security.rego            # EC2 security policies (IMDSv2, monitoring, termination)
├── ec2_security_test.rego       # EC2 security tests
│
├── rds_security.rego            # RDS security policies (public access, backups, Multi-AZ)
├── rds_security_test.rego       # RDS security tests
│
├── network_security.rego        # Network policies (VPC, security groups, flow logs)
├── network_security_test.rego   # Network security tests
│
├── iam_security.rego            # IAM policies (policies, roles)
├── monitoring.rego              # Monitoring policies (CloudTrail, GuardDuty, Config)
├── monitoring_test.rego         # Monitoring tests
│
├── compute.rego                 # Compute policies (Lambda, Load Balancers)
├── tagging.rego                 # Tagging policies
│
└── *.rego.backup                # Backup of old monolithic files

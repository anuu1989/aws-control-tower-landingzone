# OPA Encryption Policy Tests
package terraform.controltower.encryption

test_s3_bucket_encryption_required {
    deny["S3 bucket 'aws_s3_bucket.test' must have encryption enabled"] with input as {
        "planned_values": {
            "root_module": {
                "resources": [
                    {
                        "address": "aws_s3_bucket.test",
                        "type": "aws_s3_bucket",
                        "values": {"bucket": "test-bucket"}
                    }
                ]
            }
        }
    }
}

test_s3_bucket_with_encryption_passes {
    not deny[_] with input as {
        "planned_values": {
            "root_module": {
                "resources": [
                    {
                        "address": "aws_s3_bucket.test",
                        "type": "aws_s3_bucket",
                        "values": {"bucket": "test-bucket"}
                    },
                    {
                        "address": "aws_s3_bucket_server_side_encryption_configuration.test",
                        "type": "aws_s3_bucket_server_side_encryption_configuration",
                        "values": {"bucket": "aws_s3_bucket.test"}
                    }
                ]
            }
        }
    }
}

test_ebs_volume_encryption_required {
    deny["EBS volume 'aws_ebs_volume.test' must be encrypted"] with input as {
        "planned_values": {
            "root_module": {
                "resources": [
                    {
                        "address": "aws_ebs_volume.test",
                        "type": "aws_ebs_volume",
                        "values": {"encrypted": false}
                    }
                ]
            }
        }
    }
}

test_kms_key_rotation_required {
    deny["KMS key 'aws_kms_key.test' must have automatic key rotation enabled"] with input as {
        "planned_values": {
            "root_module": {
                "resources": [
                    {
                        "address": "aws_kms_key.test",
                        "type": "aws_kms_key",
                        "values": {"enable_key_rotation": false}
                    }
                ]
            }
        }
    }
}

test_rds_encryption_required {
    deny["RDS instance 'aws_db_instance.test' must have storage encryption enabled"] with input as {
        "planned_values": {
            "root_module": {
                "resources": [
                    {
                        "address": "aws_db_instance.test",
                        "type": "aws_db_instance",
                        "values": {"storage_encrypted": false}
                    }
                ]
            }
        }
    }
}

test_elasticache_encryption_at_rest_required {
    deny["ElastiCache replication group 'aws_elasticache_replication_group.test' must have encryption at rest enabled"] with input as {
        "planned_values": {
            "root_module": {
                "resources": [
                    {
                        "address": "aws_elasticache_replication_group.test",
                        "type": "aws_elasticache_replication_group",
                        "values": {
                            "at_rest_encryption_enabled": false,
                            "transit_encryption_enabled": true
                        }
                    }
                ]
            }
        }
    }
}

test_secrets_kms_encryption_required {
    deny["Secrets Manager secret 'aws_secretsmanager_secret.test' must use KMS encryption"] with input as {
        "planned_values": {
            "root_module": {
                "resources": [
                    {
                        "address": "aws_secretsmanager_secret.test",
                        "type": "aws_secretsmanager_secret",
                        "values": {}
                    }
                ]
            }
        }
    }
}

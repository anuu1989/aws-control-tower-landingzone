# OPA RDS Security Policy Tests
package terraform.controltower.rds

test_rds_public_access_denied {
    deny["RDS instance 'aws_db_instance.test' must not be publicly accessible"] with input as {
        "planned_values": {
            "root_module": {
                "resources": [
                    {
                        "address": "aws_db_instance.test",
                        "type": "aws_db_instance",
                        "values": {
                            "publicly_accessible": true,
                            "storage_encrypted": true,
                            "backup_retention_period": 7
                        }
                    }
                ]
            }
        }
    }
}

test_rds_backup_retention_required {
    deny["RDS instance 'aws_db_instance.test' must have backup retention period of at least 7 days"] with input as {
        "planned_values": {
            "root_module": {
                "resources": [
                    {
                        "address": "aws_db_instance.test",
                        "type": "aws_db_instance",
                        "values": {
                            "publicly_accessible": false,
                            "storage_encrypted": true,
                            "backup_retention_period": 3
                        }
                    }
                ]
            }
        }
    }
}

test_production_rds_multi_az_required {
    deny["Production RDS instance 'aws_db_instance.prod' must be Multi-AZ"] with input as {
        "planned_values": {
            "root_module": {
                "resources": [
                    {
                        "address": "aws_db_instance.prod",
                        "type": "aws_db_instance",
                        "values": {
                            "publicly_accessible": false,
                            "storage_encrypted": true,
                            "backup_retention_period": 7,
                            "multi_az": false,
                            "tags": {"Environment": "prod"}
                        }
                    }
                ]
            }
        }
    }
}

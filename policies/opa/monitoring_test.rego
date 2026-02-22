# OPA Monitoring Policy Tests
package terraform.controltower.monitoring

test_cloudtrail_required {
    deny["At least one CloudTrail must be configured"] with input as {
        "planned_values": {
            "root_module": {
                "resources": []
            }
        }
    }
}

test_cloudtrail_log_validation_required {
    deny["CloudTrail 'aws_cloudtrail.test' must have log file validation enabled"] with input as {
        "planned_values": {
            "root_module": {
                "resources": [
                    {
                        "address": "aws_cloudtrail.test",
                        "type": "aws_cloudtrail",
                        "values": {
                            "enable_log_file_validation": false,
                            "is_multi_region_trail": true,
                            "include_global_service_events": true
                        }
                    }
                ]
            }
        }
    }
}

test_guardduty_required {
    deny["GuardDuty detector must be enabled"] with input as {
        "planned_values": {
            "root_module": {
                "resources": []
            }
        }
    }
}

test_config_recorder_required {
    deny["AWS Config configuration recorder must be enabled"] with input as {
        "planned_values": {
            "root_module": {
                "resources": []
            }
        }
    }
}

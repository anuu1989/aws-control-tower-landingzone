# OPA EC2 Security Policy Tests
package terraform.controltower.ec2

test_ec2_imdsv2_required {
    deny["EC2 instance 'aws_instance.test' must use IMDSv2 (http_tokens=required)"] with input as {
        "planned_values": {
            "root_module": {
                "resources": [
                    {
                        "address": "aws_instance.test",
                        "type": "aws_instance",
                        "values": {
                            "metadata_options": [{"http_tokens": "optional"}]
                        }
                    }
                ]
            }
        }
    }
}

test_ec2_with_imdsv2_passes {
    not deny[_] with input as {
        "planned_values": {
            "root_module": {
                "resources": [
                    {
                        "address": "aws_instance.test",
                        "type": "aws_instance",
                        "values": {
                            "metadata_options": [{"http_tokens": "required"}],
                            "monitoring": true,
                            "tags": {"Environment": "dev"}
                        }
                    }
                ]
            }
        }
    }
}

test_production_ec2_termination_protection {
    deny["Production EC2 instance 'aws_instance.prod' must have termination protection enabled"] with input as {
        "planned_values": {
            "root_module": {
                "resources": [
                    {
                        "address": "aws_instance.prod",
                        "type": "aws_instance",
                        "values": {
                            "metadata_options": [{"http_tokens": "required"}],
                            "disable_api_termination": false,
                            "tags": {"Environment": "prod"}
                        }
                    }
                ]
            }
        }
    }
}

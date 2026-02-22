# OPA Network Security Policy Tests
package terraform.controltower.network

test_security_group_unrestricted_ingress_denied {
    deny["Security group 'aws_security_group.test' must not allow unrestricted ingress from 0.0.0.0/0"] with input as {
        "planned_values": {
            "root_module": {
                "resources": [
                    {
                        "address": "aws_security_group.test",
                        "type": "aws_security_group",
                        "values": {
                            "ingress": [
                                {
                                    "cidr_blocks": ["0.0.0.0/0"],
                                    "from_port": 0,
                                    "to_port": 0
                                }
                            ]
                        }
                    }
                ]
            }
        }
    }
}

test_security_group_ssh_from_anywhere_denied {
    deny["Security group 'aws_security_group.test' must not allow SSH (port 22) from 0.0.0.0/0"] with input as {
        "planned_values": {
            "root_module": {
                "resources": [
                    {
                        "address": "aws_security_group.test",
                        "type": "aws_security_group",
                        "values": {
                            "ingress": [
                                {
                                    "cidr_blocks": ["0.0.0.0/0"],
                                    "from_port": 22,
                                    "to_port": 22
                                }
                            ]
                        }
                    }
                ]
            }
        }
    }
}

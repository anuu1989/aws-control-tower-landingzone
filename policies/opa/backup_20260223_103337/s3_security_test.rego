# OPA S3 Security Policy Tests
package terraform.controltower.s3

test_s3_public_access_block_required {
    deny["S3 bucket 'aws_s3_bucket.test' must have public access blocked"] with input as {
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

test_s3_with_public_access_block_passes {
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
                        "address": "aws_s3_bucket_public_access_block.test",
                        "type": "aws_s3_bucket_public_access_block",
                        "values": {
                            "bucket": "aws_s3_bucket.test",
                            "block_public_acls": true,
                            "block_public_policy": true,
                            "ignore_public_acls": true,
                            "restrict_public_buckets": true
                        }
                    }
                ]
            }
        }
    }
}

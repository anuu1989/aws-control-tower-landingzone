output "log_group_names" {
  description = "Map of log group names"
  value = {
    application = aws_cloudwatch_log_group.application.name
    lambda      = aws_cloudwatch_log_group.lambda.name
    ecs         = aws_cloudwatch_log_group.ecs.name
  }
}

output "log_group_arns" {
  description = "Map of log group ARNs"
  value = {
    application = aws_cloudwatch_log_group.application.arn
    lambda      = aws_cloudwatch_log_group.lambda.arn
    ecs         = aws_cloudwatch_log_group.ecs.arn
  }
}

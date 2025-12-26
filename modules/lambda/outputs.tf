output "function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.function.arn
}

output "function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.function.function_name
}

output "invoke_arn" {
  description = "Invoke ARN of the Lambda function"
  value       = aws_lambda_function.function.invoke_arn
}

output "qualified_arn" {
  description = "Qualified ARN of the Lambda function"
  value       = aws_lambda_function.function.qualified_arn
}

output "role_arn" {
  description = "ARN of the IAM role for the Lambda function"
  value       = aws_iam_role.lambda_execution_role.arn
}

output "role_name" {
  description = "Name of the IAM role for the Lambda function"
  value       = aws_iam_role.lambda_execution_role.name
}

output "function_version" {
  description = "Latest published version of the Lambda function"
  value       = aws_lambda_function.function.version
}

output "source_code_hash" {
  description = "Base64-encoded SHA256 hash of the package file"
  value       = aws_lambda_function.function.source_code_hash
}

# output "api_gateway_resource_id" {
#   description = "ID of the API Gateway resource (if created)"
#   value       = var.api_gateway_config != null ? aws_api_gateway_resource.api_resource[0].id : null
# }

output "eventbridge_rule_arn" {
  description = "ARN of the EventBridge rule (if created)"
  value       = var.eventbridge_config != null ? aws_cloudwatch_event_rule.eventbridge_rule[0].arn : null
}

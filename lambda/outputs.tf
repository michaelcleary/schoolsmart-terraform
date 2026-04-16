output "cognito_migration_function_arn" {
  description = "ARN of the Cognito user-migration Lambda"
  value       = module.cognito_migration_lambda.function_arn
}

output "cognito_migration_function_name" {
  description = "Name of the Cognito user-migration Lambda"
  value       = module.cognito_migration_lambda.function_name
}

output "cognito_pretokengen_function_arn" {
  description = "ARN of the Cognito pre-token-generation Lambda"
  value       = module.cognito_pretokengen_lambda.function_arn
}

output "cognito_pretokengen_function_name" {
  description = "Name of the Cognito pre-token-generation Lambda"
  value       = module.cognito_pretokengen_lambda.function_name
}

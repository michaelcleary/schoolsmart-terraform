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

output "nextjs_server_function_arn" {
  description = "ARN of the OpenNext Next.js server Lambda (null if enable_nextjs_lambda is false)"
  value       = var.enable_nextjs_lambda ? module.nextjs_server_lambda[0].function_arn : null
}

output "nextjs_server_function_name" {
  description = "Name of the OpenNext Next.js server Lambda (null if enable_nextjs_lambda is false)"
  value       = var.enable_nextjs_lambda ? module.nextjs_server_lambda[0].function_name : null
}

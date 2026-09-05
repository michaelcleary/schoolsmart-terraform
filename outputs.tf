# Main site outputs
# output "main_site_s3_bucket_url" {
#   value       = module.main_site.s3_website_endpoint
#   description = "The main site S3 bucket website URL"
# }

# output "main_site_cloudfront_url" {
#   value       = module.main_site.cloudfront_distribution_domain_name
#   description = "The main site CloudFront distribution URL"
# }

# output "main_site_domain" {
#   value       = module.main_site.domain_name
#   description = "The main site domain name"
# }

# Admin site outputs
# output "admin_site_s3_bucket_url" {
#   value       = module.admin_site.s3_website_endpoint
#   description = "The admin site S3 bucket website URL"
# }

# output "admin_site_cloudfront_url" {
#   value       = module.admin_site.cloudfront_distribution_domain_name
#   description = "The admin site CloudFront distribution URL"
# }

output "admin_site_domain" {
  value       = module.admin_site.domain_name
  description = "The admin site domain name"
}

output "nextjs_assets_bucket_name" {
  value       = local.nextjs_assets_bucket_name
  description = "Name of the dedicated S3 bucket for OpenNext static assets — set schoolsmart-admin's S3_NEXT_ASSETS_BUCKET CI var to this"
}

output "nextjs_site_domain" {
  value       = var.enable_nextjs_lambda_hosting ? module.nextjs_site[0].domain_name : null
  description = "Temporary validation domain for the OpenNext CloudFront distribution — see nextjs-site.tf. Not the real app domain until schoolsmart-terraform-yd1 cuts over. Null until enable_nextjs_lambda_hosting is true."
}

output "nextjs_server_function_name" {
  value       = module.lambda.nextjs_server_function_name
  description = "Name of the OpenNext Next.js server Lambda (null until enable_nextjs_lambda_hosting is true)"
}

# App Runner outputs
# output "app_runner_service_url" {
#   value       = aws_apprunner_service.app_server.service_url
#   description = "The App Runner service URL"
# }
#
# output "app_runner_service_arn" {
#   value       = aws_apprunner_service.app_server.arn
#   description = "The App Runner service ARN"
# }

output "app_runner_api_endpoint" {
  value       = "https://${var.api_domain_name}${var.app_runner_api_prefix}"
  description = "The API endpoint for the App Runner service"
}

output "api_gateway_v2_api_id" {
  value       = aws_apigatewayv2_api.admin_api.id
  description = "The ID of the API Gateway V2 (HTTP API)"
}

output "amplify_app_id" {
  value       = var.retire_amplify ? null : module.amplify[0].app_id
  description = "Amplify app ID — needed by CI/CD to trigger deployments (aws amplify start-job). Null once retire_amplify retires this env's Amplify app (schoolsmart-terraform-yd1)."
}

output "amplify_branch_name" {
  value       = var.retire_amplify ? null : module.amplify[0].branch_name
  description = "Amplify branch being deployed. Null once retire_amplify retires this env's Amplify app (schoolsmart-terraform-yd1)."
}

output "amplify_domain" {
  value       = var.retire_amplify ? null : module.amplify[0].custom_domain
  description = "Custom domain for the NextJS app. Null once retire_amplify retires this env's Amplify app (schoolsmart-terraform-yd1) — see nextjs_site_domain instead."
}

output "cognito_user_pool_id" {
  value       = aws_cognito_user_pool.main.id
  description = "Cognito User Pool ID — needed by the Next.js and API server apps"
}

output "cognito_client_id" {
  value       = aws_cognito_user_pool_client.nextjs.id
  description = "Cognito App Client ID for the Next.js application"
}

output "cognito_user_pool_arn" {
  value       = aws_cognito_user_pool.main.arn
  description = "Cognito User Pool ARN"
}

# output "app_runner_cloudfront_domain" {
#   value       = aws_cloudfront_distribution.app_runner_distribution.domain_name
#   description = "The CloudFront domain for the App Runner service"
# }

# SES outputs
# output "ses_domain_identity_arn" {
#   value       = aws_ses_domain_identity.main.arn
#   description = "The ARN of the SES domain identity"
# }
#
# output "ses_smtp_user_access_key_id" {
#   value       = aws_iam_access_key.ses_smtp_user.id
#   description = "The SMTP username (access key ID)"
#   sensitive   = true
# }
#
# output "ses_smtp_user_secret_access_key" {
#   value       = aws_iam_access_key.ses_smtp_user.secret
#   description = "The SMTP password (secret access key)"
#   sensitive   = true
# }
#
# output "ses_smtp_endpoint" {
#   value       = "email-smtp.${var.aws_region}.amazonaws.com"
#   description = "The SES SMTP endpoint"
# }
#
# output "ses_sending_role_arn" {
#   value       = aws_iam_role.ses_sending_role.arn
#   description = "The ARN of the IAM role for services to send emails"
# }
#
# output "ses_configuration_set_name" {
#   value       = aws_ses_configuration_set.main.name
#   description = "The name of the SES configuration set"
# }

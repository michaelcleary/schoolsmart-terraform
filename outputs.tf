# Main site outputs
output "main_site_s3_bucket_url" {
  value       = module.main_site.s3_website_endpoint
  description = "The main site S3 bucket website URL"
}

output "main_site_cloudfront_url" {
  value       = module.main_site.cloudfront_distribution_domain_name
  description = "The main site CloudFront distribution URL"
}

output "main_site_domain" {
  value       = module.main_site.domain_name
  description = "The main site domain name"
}

# Admin site outputs
output "admin_site_s3_bucket_url" {
  value       = module.admin_site.s3_website_endpoint
  description = "The admin site S3 bucket website URL"
}

output "admin_site_cloudfront_url" {
  value       = module.admin_site.cloudfront_distribution_domain_name
  description = "The admin site CloudFront distribution URL"
}

output "admin_site_domain" {
  value       = module.admin_site.domain_name
  description = "The admin site domain name"
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
  value       = "https://api.${var.main_domain_name}${var.app_runner_api_prefix}"
  description = "The API endpoint for the App Runner service"
}

# output "app_runner_cloudfront_domain" {
#   value       = aws_cloudfront_distribution.app_runner_distribution.domain_name
#   description = "The CloudFront domain for the App Runner service"
# }

# SES outputs
output "ses_domain_identity_arn" {
  value       = aws_ses_domain_identity.main.arn
  description = "The ARN of the SES domain identity"
}

output "ses_smtp_user_access_key_id" {
  value       = aws_iam_access_key.ses_smtp_user.id
  description = "The SMTP username (access key ID)"
  sensitive   = true
}

output "ses_smtp_user_secret_access_key" {
  value       = aws_iam_access_key.ses_smtp_user.secret
  description = "The SMTP password (secret access key)"
  sensitive   = true
}

output "ses_smtp_endpoint" {
  value       = "email-smtp.${var.aws_region}.amazonaws.com"
  description = "The SES SMTP endpoint"
}

output "ses_sending_role_arn" {
  value       = aws_iam_role.ses_sending_role.arn
  description = "The ARN of the IAM role for services to send emails"
}

output "ses_configuration_set_name" {
  value       = aws_ses_configuration_set.main.name
  description = "The name of the SES configuration set"
}

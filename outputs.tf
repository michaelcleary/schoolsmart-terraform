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

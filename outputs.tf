output "s3_bucket_url" {
  value       = aws_s3_bucket_website_configuration.website_config.website_endpoint
  description = "The S3 bucket website URL"
}

output "cloudfront_url" {
  value       = var.enable_cloudfront ? aws_cloudfront_distribution.s3_distribution.domain_name : ""
  description = "The CloudFront distribution URL, or an empty string if CloudFront is disabled."
}

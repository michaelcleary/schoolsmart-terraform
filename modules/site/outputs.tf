# output "s3_bucket_name" {
#   description = "Name of the S3 bucket hosting the static website"
#   value       = aws_s3_bucket.static_website.bucket
# }
#
# output "s3_bucket_arn" {
#   description = "ARN of the S3 bucket hosting the static website"
#   value       = aws_s3_bucket.static_website.arn
# }

# output "s3_website_endpoint" {
#   description = "Website endpoint for the S3 bucket"
#   value       = aws_s3_bucket_website_configuration.website_config.website_endpoint
# }

# output "cloudfront_distribution_id" {
#   description = "ID of the CloudFront distribution"
#   value       = var.enable_cloudfront ? aws_cloudfront_distribution.s3_distribution[0].id : null
# }
#
# output "cloudfront_distribution_domain_name" {
#   description = "Domain name of the CloudFront distribution"
#   value       = var.enable_cloudfront ? aws_cloudfront_distribution.s3_distribution[0].domain_name : null
# }
#
# output "cloudfront_distribution_arn" {
#   description = "ARN of the CloudFront distribution"
#   value       = var.enable_cloudfront ? aws_cloudfront_distribution.s3_distribution[0].arn : null
# }

# output "acm_certificate_arn" {
#   description = "ARN of the ACM certificate"
#   value       = aws_acm_certificate.cert.arn
# }

output "domain_name" {
  description = "Domain name of the site"
  value       = var.domain_name
}
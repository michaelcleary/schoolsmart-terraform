
# A record for the apex domain pointing to CloudFront
resource "aws_route53_record" "main" {
  provider = aws.shared
  count   = var.enable_route53 ? 1 : 0
  zone_id = var.hosted_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution[0].domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution[0].hosted_zone_id
    evaluate_target_health = false
  }

  depends_on = [aws_cloudfront_distribution.s3_distribution]
}
#
# # A record for the www subdomain pointing to CloudFront (if enabled)
# resource "aws_route53_record" "www" {
#   count   = var.enable_route53 && var.use_www_subdomain ? 1 : 0
#   zone_id = var.create_hosted_zone ? aws_route53_zone.primary[0].zone_id : var.hosted_zone_id
#   name    = "www.${var.domain_name}"
#   type    = "A"
#
#   alias {
#     name                   = aws_cloudfront_distribution.s3_distribution[0].domain_name
#     zone_id                = aws_cloudfront_distribution.s3_distribution[0].hosted_zone_id
#     evaluate_target_health = false
#   }
#
#   depends_on = [aws_cloudfront_distribution.s3_distribution]
# }
#
# # CNAME record for the API subdomain (if enabled)
# resource "aws_route53_record" "api_gateway_record" {
#   count   = var.enable_route53 && var.create_api_subdomain ? 1 : 0
#   zone_id = var.create_hosted_zone ? aws_route53_zone.primary[0].zone_id : var.hosted_zone_id
#   name    = "api.schoolsmart.co.uk"
#   type    = "CNAME"
#   records = [var.api_gateway_domain_name]
#   ttl     = 60
# }

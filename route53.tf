resource "aws_route53_zone" "primary" {
  name = var.domain_name
}

resource "aws_route53_record" "main" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "api_cert_validation" {
  allow_overwrite = true
  name            = "api.${var.domain_name}"
  type            = "CNAME"
  records = [
    aws_apigatewayv2_domain_name.web_service_api_domain_name.domain_name_configuration[0].target_domain_name
  ]
  zone_id = aws_route53_zone.primary.zone_id
  ttl     = 60
}


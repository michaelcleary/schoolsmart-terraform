resource "aws_acm_certificate" "cert" {
  provider          = aws.virginia
  domain_name       = var.domain_name
  validation_method = "DNS"

  # List of subject alternative names based on configuration
  subject_alternative_names = var.use_www_subdomain ? ["www.${var.domain_name}"] : []

  tags = {
    Name        = "ACM-Certificate-${var.domain_name}"
    Environment = var.env
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ACM DNS Validation using Route 53
resource "aws_route53_record" "cert_validation" {
  provider = aws.shared
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }

  zone_id = var.hosted_zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.value]
}

resource "aws_acm_certificate_validation" "cert_validation" {
  provider                = aws.virginia
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

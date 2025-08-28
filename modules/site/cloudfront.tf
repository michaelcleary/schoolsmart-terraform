resource "aws_cloudfront_origin_access_identity" "origin_identity" {
  comment = "Origin Access Identity for CloudFront to access S3 for ${var.domain_name}"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  count = var.enable_cloudfront ? 1 : 0
  
  enabled             = true
  default_root_object = "index.html"

  origin {
    domain_name = aws_s3_bucket.static_website.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.static_website.id
    origin_path = var.origin_path

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_identity.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.static_website.id

    viewer_protocol_policy = "redirect-to-https"
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # Dynamic aliases based on configuration
  aliases = concat(
    [var.domain_name],
    var.use_www_subdomain ? ["www.${var.domain_name}"] : []
  )

  tags = {
    Name        = "CloudFrontDistribution-${var.domain_name}"
    Environment = var.env
  }

  depends_on = [
    aws_acm_certificate_validation.cert_validation,
    aws_acm_certificate.cert
  ]
}
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

  dynamic "origin" {
    for_each = var.enable_api_gateway ? [1] : []
    content {
      domain_name = var.api_invoke_url
      origin_id   = "APIGatewayOrigin"

      custom_origin_config {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "https-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
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

  dynamic "ordered_cache_behavior" {
    for_each = var.enable_api_gateway ? [1] : []
    content {
      path_pattern           = "/auth/*"
      target_origin_id       = "APIGatewayOrigin"
      viewer_protocol_policy = "redirect-to-https"
      allowed_methods        = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
      cached_methods         = ["HEAD", "GET", "OPTIONS"]
      forwarded_values {
        query_string = true
        headers      = ["Authorization"]
        cookies {
          forward = "all"
        }
      }
    }
  }

  dynamic "ordered_cache_behavior" {
    for_each = var.enable_api_gateway ? [1] : []
    content {
      path_pattern           = "/api/*"
      target_origin_id       = "APIGatewayOrigin"
      viewer_protocol_policy = "redirect-to-https"
      allowed_methods        = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
      cached_methods         = ["HEAD", "GET", "OPTIONS"]
      forwarded_values {
        query_string = true
        headers      = ["Authorization"]
        cookies {
          forward = "all"
        }
      }
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
  }

  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
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
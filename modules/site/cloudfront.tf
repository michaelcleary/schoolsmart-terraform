data "aws_s3_bucket" "static_website" {
  provider = aws.shared
  bucket   = var.website_bucket_name
}

resource "aws_cloudfront_origin_access_identity" "origin_identity" {
  comment = "Origin Access Identity for CloudFront to access S3 for ${var.domain_name}"
}

resource "aws_cloudfront_origin_access_control" "s3" {
  # OAC names must be unique per account. env alone isn't a unique key once more than one
  # modules/site instance shares an env (admin_site, nextjs_site, ...), so key off
  # domain_name too, same as this module's aliases/cert/tags already do.
  name                              = "${var.env}-${replace(var.domain_name, ".", "-")}-s3-oac"
  description                       = "OAC for S3 bucket in shared services"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"

  # Renaming forces replacement; create the new OAC and let the distribution update to
  # reference it before the old one is destroyed, so a live distribution is never left
  # pointing at a deleted OAC mid-apply.
  lifecycle {
    create_before_destroy = true
  }
}

# OAC for a Lambda Function URL default origin (see var.default_origin_requires_oac) —
# a Function URL with AWS_IAM auth needs SigV4-signed requests, same mechanism as the S3
# OAC above but origin_access_control_origin_type = "lambda".
resource "aws_cloudfront_origin_access_control" "lambda_url" {
  count                             = var.default_origin_requires_oac ? 1 : 0
  name                              = "${var.env}-${replace(var.domain_name, ".", "-")}-lambda-oac"
  description                       = "OAC for Lambda Function URL origin"
  origin_access_control_origin_type = "lambda"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  count = var.enable_cloudfront ? 1 : 0

  enabled             = true
  default_root_object = "index.html"

  origin {
    domain_name              = data.aws_s3_bucket.static_website.bucket_regional_domain_name
    origin_id                = data.aws_s3_bucket.static_website.id
    origin_path              = var.origin_path
    origin_access_control_id = aws_cloudfront_origin_access_control.s3.id

    # s3_origin_config {
    #   origin_access_identity = aws_cloudfront_origin_access_identity.origin_identity.cloudfront_access_identity_path
    # }
  }

  dynamic "origin" {
    for_each = var.enable_api_gateway ? [1] : []
    content {
      domain_name               = var.api_invoke_url
      origin_id                 = "APIGatewayOrigin"
      origin_access_control_id  = var.default_origin_requires_oac ? aws_cloudfront_origin_access_control.lambda_url[0].id : null

      dynamic "custom_header" {
        for_each = var.default_origin_custom_headers
        content {
          name  = custom_header.key
          value = custom_header.value
        }
      }

      custom_origin_config {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "https-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }
  }

  default_cache_behavior {
    allowed_methods  = var.api_gateway_is_default ? ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"] : ["GET", "HEAD"]
    cached_methods   = var.api_gateway_is_default ? ["HEAD", "GET", "OPTIONS"] : ["GET", "HEAD"]
    target_origin_id = var.api_gateway_is_default ? "APIGatewayOrigin" : data.aws_s3_bucket.static_website.id

    viewer_protocol_policy = "redirect-to-https"
    forwarded_values {
      query_string = var.api_gateway_is_default
      # Forwarding the viewer's own Authorization header conflicts with an OAC'd origin
      # (Lambda Function URL): CloudFront injects its own SigV4-signed Authorization header
      # at the origin-request stage, and forwarding the viewer's here overwrites/corrupts
      # it, causing a 403 straight from the Function URL's auth layer before Lambda ever
      # runs. Only forward it for the plain-API-Gateway case, which doesn't use OAC.
      headers      = (var.api_gateway_is_default && !var.default_origin_requires_oac) ? ["Authorization"] : []
      cookies {
        forward = var.api_gateway_is_default ? "all" : "none"
      }
    }
  }

  # /auth/*, /api/* ordered behaviors assume API Gateway is the secondary origin behind
  # a default S3 behavior (the Angular admin client pattern). Skipped when API Gateway is
  # already the default behavior (the SSR pattern) since it already handles those paths.
  dynamic "ordered_cache_behavior" {
    for_each = var.enable_api_gateway && !var.api_gateway_is_default ? [1] : []
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
    for_each = var.enable_api_gateway && !var.api_gateway_is_default ? [1] : []
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

  # Static asset prefixes routed to the S3 origin instead of the Lambda default behavior
  # (SSR pattern only — see api_gateway_is_default).
  dynamic "ordered_cache_behavior" {
    for_each = var.api_gateway_is_default ? var.static_asset_path_patterns : []
    content {
      path_pattern           = ordered_cache_behavior.value
      target_origin_id       = data.aws_s3_bucket.static_website.id
      viewer_protocol_policy = "redirect-to-https"
      allowed_methods        = ["GET", "HEAD"]
      cached_methods         = ["GET", "HEAD"]
      forwarded_values {
        query_string = false
        cookies {
          forward = "none"
        }
      }
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  # SPA-style rewrite of 403/404 to /index.html only makes sense when S3 is serving a
  # client-routed app. The SSR pattern (api_gateway_is_default) handles its own routing
  # and error pages via the Lambda origin.
  dynamic "custom_error_response" {
    for_each = var.api_gateway_is_default ? [] : [403, 404]
    content {
      error_code         = custom_error_response.value
      response_code      = 200
      response_page_path = "/index.html"
    }
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
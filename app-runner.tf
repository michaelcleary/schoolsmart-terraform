resource "aws_iam_role" "app_runner_service_role" {
  name = "app-runner-service-role-${var.env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "build.apprunner.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "AppRunnerServiceRole"
    Environment = var.env
  }
}

resource "aws_iam_role" "app_runner_ssm_role" {
  name = "${var.env}_apprunner_ssm_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "tasks.apprunner.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "ssm_read_policy" {
  name        = "${var.env}_apprunner_SSMReadPolicy"
  description = "Allow App Runner to read SSM parameters"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = [
        "ssm:GetParameter",
        "ssm:GetParameters",
        "ssm:GetParametersByPath"
      ],
      Resource = "arn:aws:ssm:eu-west-2:${var.aws_account}:parameter/schoolsmart/*"
    }]
  })
}

resource "aws_iam_policy" "s3_read_write_policy" {
  name        = "${var.env}_apprunner_S3ReadWrite"
  description = "Allow App Runner to read and write S3 documents"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = [
        "s3:GetObject",
        "s3:PutObject"
      ],
      Resource = "arn:aws:s3:::${var.app_runner_environment_variables.S3_BUCKET}/*"
    }]
  })
}

resource "aws_iam_policy" "dynamodb_read_write_policy" {
  name        = "${var.env}_apprunner_DynamoDBReadWrite"
  description = "Allow App Runner to read and write DynamoDB tables"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = [
        "dynamodb:BatchGetItem",
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:Scan",
        "dynamodb:Query"
      ],
      "Resource": [
        "arn:aws:dynamodb:${var.aws_region}:${var.aws_account}:table/*",
        "arn:aws:dynamodb:${var.aws_region}:${var.aws_account}:table/*/index/*"
      ]
    }]
  })
}

resource "aws_iam_policy" "ses_send_email_policy" {
  name        = "${var.env}_apprunner_SESSendEmail"
  description = "Allow App Runner to send emails via SES"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = [
        "ses:SendEmail",
        "ses:SendRawEmail"
      ],
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "app_runner_ecr_access" {
  role       = aws_iam_role.app_runner_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess"
}

resource "aws_iam_role_policy_attachment" "app_runner_ssm_access" {
  role       = aws_iam_role.app_runner_ssm_role.name
  policy_arn = aws_iam_policy.ssm_read_policy.arn
}

resource "aws_iam_role_policy_attachment" "app_runner_s3_access" {
  role       = aws_iam_role.app_runner_ssm_role.name
  policy_arn = aws_iam_policy.s3_read_write_policy.arn
}

resource "aws_iam_role_policy_attachment" "app_runner_dynamodb_access" {
  role       = aws_iam_role.app_runner_ssm_role.name
  policy_arn = aws_iam_policy.dynamodb_read_write_policy.arn
}

resource "aws_iam_role_policy_attachment" "app_runner_ses_access" {
  role       = aws_iam_role.app_runner_ssm_role.name
  policy_arn = aws_iam_policy.ses_send_email_policy.arn
}

resource "aws_apprunner_service" "app_server" {
  service_name = "app-server-${var.env}"

  source_configuration {
    authentication_configuration {
      access_role_arn = aws_iam_role.app_runner_service_role.arn
    }

    image_repository {
      image_configuration {
        port = var.app_runner_port
        runtime_environment_variables = var.app_runner_environment_variables
      }
      image_identifier      = "${var.app_runner_ecr_repo_url}:${var.app_runner_image_tag}"
      image_repository_type = "ECR"
    }

    auto_deployments_enabled = var.app_runner_auto_deployments_enabled
  }

  instance_configuration {
    cpu    = var.app_runner_cpu
    memory = var.app_runner_memory
    instance_role_arn = aws_iam_role.app_runner_ssm_role.arn
  }

  tags = {
    Name        = "AppServer"
    Environment = var.env
  }
}

# Create an ACM certificate for the CloudFront distribution
# resource "aws_acm_certificate" "app_runner_cert" {
#   provider          = aws.virginia  # CloudFront requires certificates in us-east-1
#   domain_name       = var.main_domain_name
#   validation_method = "DNS"
#
#   subject_alternative_names = [
#     "*.${var.main_domain_name}"
#   ]
#
#   lifecycle {
#     create_before_destroy = true
#   }
#
#   tags = {
#     Name        = "AppRunnerCertificate"
#     Environment = var.env
#   }
# }

# Create a CloudFront distribution to route API requests to App Runner
# resource "aws_cloudfront_distribution" "app_runner_distribution" {
#   enabled = true
#   comment = "Distribution for App Runner API (${var.app_runner_api_prefix})"
#
#   # Origin for the App Runner service
#   origin {
#     domain_name = aws_apprunner_service.app_server.service_url
#     origin_id   = "appRunnerOrigin"
#
#     custom_origin_config {
#       http_port              = 80
#       https_port             = 443
#       origin_protocol_policy = "https-only"
#       origin_ssl_protocols   = ["TLSv1.2"]
#     }
#   }
#
#   # Default behavior for non-API requests - redirect to main site
#   default_cache_behavior {
#     allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
#     cached_methods         = ["GET", "HEAD", "OPTIONS"]
#     target_origin_id = "appRunnerOrigin"
#
#     forwarded_values {
#       query_string = true
#       headers      = ["Authorization", "Origin", "Content-Type"]
#       cookies {
#         forward = "none"
#       }
#     }
#
#     viewer_protocol_policy = "redirect-to-https"
#     min_ttl                = 0
#     default_ttl            = 3600
#     max_ttl                = 86400
#   }
#
#   # Cache behavior for API requests
#   ordered_cache_behavior {
#     path_pattern     = "${var.app_runner_api_prefix}/*"
#     allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
#     cached_methods   = ["GET", "HEAD"]
#     target_origin_id = "appRunnerOrigin"
#
#     forwarded_values {
#       query_string = true
#       headers      = ["Authorization", "Origin", "Content-Type"]
#       cookies {
#         forward = "all"
#       }
#     }
#
#     viewer_protocol_policy = "redirect-to-https"
#     min_ttl                = 0
#     default_ttl            = 0
#     max_ttl                = 0
#   }
#
#   price_class = "PriceClass_100"
#
#   restrictions {
#     geo_restriction {
#       restriction_type = "none"
#     }
#   }
#
#   viewer_certificate {
#     acm_certificate_arn      = aws_acm_certificate.app_runner_cert.arn
#     ssl_support_method       = "sni-only"
#     minimum_protocol_version = "TLSv1.2_2021"
#   }
#
#   aliases = [
#     "api.${var.main_domain_name}"
#   ]
#
#   tags = {
#     Name        = "AppRunnerDistribution"
#     Environment = var.env
#   }
# }

# Create DNS records for the API subdomain
# resource "aws_route53_record" "app_runner_api" {
#   zone_id = module.main_site.route53_zone_id
#   name    = "api.${var.main_domain_name}"
#   type    = "A"
#
#   alias {
#     name                   = aws_cloudfront_distribution.app_runner_distribution.domain_name
#     zone_id                = aws_cloudfront_distribution.app_runner_distribution.hosted_zone_id
#     evaluate_target_health = false
#   }
# }


# SG for App Runner
# resource "aws_security_group" "apprunner" {
#   name        = "apprunner_sg"
#   description = "App Runner SG for outbound to MongoDB"
#   vpc_id      = var.vpc
# }
#
# # Allow outbound to anywhere (App Runner → MongoDB controlled by Mongo SG)
# resource "aws_security_group_rule" "apprunner_outbound" {
#   type              = "egress"
#   from_port         = 443
#   to_port           = 443
#   protocol          = "-1"
#   cidr_blocks       = ["0.0.0.0/0"]
#   security_group_id = aws_security_group.apprunner.id
# }

# resource "aws_security_group" "vpc_endpoints" {
#   name        = "vpc-endpoints-sg"
#   description = "Security group for VPC endpoints"
#   vpc_id      = var.vpc
#
#   ingress {
#     description = "HTTPS from App Runner"
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     security_groups = [aws_security_group.apprunner.id]
#   }
#
#   ingress {
#     description = "HTTPS from VPC"
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
#   }
#
#   egress {
#     description = "All outbound traffic"
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#
#   tags = {
#     Name = "vpc-endpoints-sg"
#   }
# }

# resource "aws_apprunner_vpc_connector" "connector" {
#   vpc_connector_name = "apprunner-to-mongo"
#
#   subnets         = ["subnet-082c49638a8f581ef", "subnet-0d2a19b9ffa1735cc", "subnet-015b1a8997d54cd5b"]
#   security_groups = [aws_security_group.apprunner.id]
# }
# DNS validation records for the App Runner certificate
# resource "aws_route53_record" "app_runner_cert_validation" {
#   for_each = {
#     for dvo in aws_acm_certificate.app_runner_cert.domain_validation_options : dvo.domain_name => {
#       name   = dvo.resource_record_name
#       record = dvo.resource_record_value
#       type   = dvo.resource_record_type
#     }
#   }
#
#   zone_id = module.main_site.route53_zone_id
#   name    = each.value.name
#   type    = each.value.type
#   records = [each.value.record]
#   ttl     = 60
# }
#
# # Certificate validation
# resource "aws_acm_certificate_validation" "app_runner_cert_validation" {
#   provider                = aws.virginia
#   certificate_arn         = aws_acm_certificate.app_runner_cert.arn
#   validation_record_fqdns = [for record in aws_route53_record.app_runner_cert_validation : record.fqdn]
# }

# Create a custom domain for the App Runner service if enabled
# resource "aws_apprunner_custom_domain_association" "app_server" {
#   count = var.app_runner_enable_custom_domain ? 1 : 0
#
#   domain_name          = var.app_runner_domain_name
#   service_arn          = aws_apprunner_service.app_server.arn
#   enable_www_subdomain = var.app_runner_enable_www_subdomain
# }

# Interface Endpoint for SSM
# resource "aws_vpc_endpoint" "ssm" {
#   vpc_id            = var.vpc
#   service_name      = "com.amazonaws.${var.aws_region}.ssm"
#   vpc_endpoint_type = "Interface"
#   subnet_ids        = ["subnet-082c49638a8f581ef", "subnet-0d2a19b9ffa1735cc", "subnet-015b1a8997d54cd5b"]
#   security_group_ids = [aws_security_group.vpc_endpoints.id]
#   private_dns_enabled = true
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Principal = "*"
#         Action = [
#           "ssm:GetParameter",
#           "ssm:GetParameters",
#           "ssm:GetParametersByPath"
#         ]
#         Resource = "*"
#       }
#     ]
#   })
# }
#
# resource "aws_vpc_endpoint" "s3" {
#   vpc_id       = var.vpc
#   service_name = "com.amazonaws.${var.app_runner_environment_variables.S3_REGION}.s3"
#   vpc_endpoint_type = "Gateway"
#
#   # Attach the endpoint to the private route tables
#   route_table_ids = [
#     "rtb-080d7ad0273f5fd5f"
#   ]
#
#   tags = {
#     Name = "s3-vpc-endpoint"
#   }
# }

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

data "aws_secretsmanager_secret_version" "github_token" {
  secret_id = var.github_token_secret_name
}

resource "aws_iam_role" "amplify" {
  name = "${var.app_name}-amplify-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "amplify.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "amplify_cloudwatch" {
  name = "cloudwatch-logs"
  role = aws_iam_role.amplify.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Resource = "arn:aws:logs:*:*:*"
    }]
  })
}

resource "aws_iam_role" "amplify_compute" {
  name = "${var.app_name}-amplify-compute-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "amplify.amazonaws.com" }
      Action    = "sts:AssumeRole"
      Condition = {
        ArnLike = {
          "aws:SourceArn" = "arn:aws:amplify:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:apps/*"
        }
        StringEquals = {
          "aws:SourceAccount" = data.aws_caller_identity.current.account_id
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "amplify_compute_cloudwatch" {
  name = "cloudwatch-logs"
  role = aws_iam_role.amplify_compute.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Resource = "arn:aws:logs:*:*:*"
    }]
  })
}

resource "aws_amplify_app" "this" {
  name                 = var.app_name
  repository           = var.repository_url
  access_token         = data.aws_secretsmanager_secret_version.github_token.secret_string
  platform             = "WEB_COMPUTE"
  iam_service_role_arn = aws_iam_role.amplify.arn
  compute_role_arn     = aws_iam_role.amplify_compute.arn

  # Build spec is defined in amplify.yml at the source repo root
  enable_auto_branch_creation = false
  enable_branch_auto_deletion = true

  environment_variables = merge({
    NODE_VERSION = "20"
  }, var.environment_variables)
}

resource "aws_cloudwatch_log_group" "amplify" {
  name              = "/aws/amplify/${aws_amplify_app.this.id}"
  retention_in_days = 30
}

resource "aws_amplify_branch" "this" {
  app_id      = aws_amplify_app.this.id
  branch_name = var.branch_name

  enable_auto_build = false
  framework         = "Next.js - SSR"
  stage             = var.stage

  environment_variables = var.branch_environment_variables
}

resource "aws_amplify_domain_association" "this" {
  app_id      = aws_amplify_app.this.id
  domain_name = var.domain_name

  sub_domain {
    branch_name = aws_amplify_branch.this.branch_name
    prefix      = var.domain_prefix
  }

  # Don't block apply waiting for SSL cert issuance — DNS must propagate first
  wait_for_verification = false
}

locals {
  # Format: "_name CNAME _value" — split to extract parts for Route53
  cert_record = split(" ", aws_amplify_domain_association.this.certificate_verification_dns_record)

  # Format: "prefix CNAME cloudfront-target" — Amplify assigns a CloudFront distribution per domain
  domain_dns_record = split(" ", tolist(aws_amplify_domain_association.this.sub_domain)[0].dns_record)
}

# SSL certificate verification record (added to shared Route53 zone)
resource "aws_route53_record" "amplify_cert_verification" {
  provider = aws.shared
  zone_id  = var.hosted_zone_id
  name     = local.cert_record[0]
  type     = "CNAME"
  ttl      = 300
  records  = [local.cert_record[2]]
}

# Domain CNAME pointing at the Amplify-assigned CloudFront distribution
resource "aws_route53_record" "amplify_domain" {
  provider = aws.shared
  zone_id  = var.hosted_zone_id
  name     = var.domain_prefix != "" ? "${var.domain_prefix}.${var.domain_name}" : var.domain_name
  type     = "CNAME"
  ttl      = 300
  records  = [local.domain_dns_record[2]]
}

# SES Domain Identity
resource "aws_ses_domain_identity" "main" {
  domain = var.main_domain_name
}

# SES Domain DKIM
resource "aws_ses_domain_dkim" "main" {
  domain = aws_ses_domain_identity.main.domain
}

# SES Domain Mail From
resource "aws_ses_domain_mail_from" "main" {
  domain           = aws_ses_domain_identity.main.domain
  mail_from_domain = "mail.${aws_ses_domain_identity.main.domain}"
}

# Route53 Records for SES Domain Verification
resource "aws_route53_record" "ses_verification" {
  count   = var.main_enable_route53 ? 1 : 0
  zone_id = module.main_site.route53_zone_id
  name    = "_amazonses.${var.main_domain_name}"
  type    = "TXT"
  ttl     = 600
  records = [aws_ses_domain_identity.main.verification_token]
}

# Route53 Records for DKIM
resource "aws_route53_record" "ses_dkim" {
  count   = var.main_enable_route53 ? 3 : 0
  zone_id = module.main_site.route53_zone_id
  name    = "${aws_ses_domain_dkim.main.dkim_tokens[count.index]}._domainkey"
  type    = "CNAME"
  ttl     = 600
  records = ["${aws_ses_domain_dkim.main.dkim_tokens[count.index]}.dkim.amazonses.com"]
}

# Route53 Records for Mail From Domain (SPF)
resource "aws_route53_record" "ses_mail_from_mx" {
  count   = var.main_enable_route53 ? 1 : 0
  zone_id = module.main_site.route53_zone_id
  name    = aws_ses_domain_mail_from.main.mail_from_domain
  type    = "MX"
  ttl     = 600
  records = ["10 feedback-smtp.${var.aws_region}.amazonses.com"]
}

resource "aws_route53_record" "ses_mail_from_txt" {
  count   = var.main_enable_route53 ? 1 : 0
  zone_id = module.main_site.route53_zone_id
  name    = aws_ses_domain_mail_from.main.mail_from_domain
  type    = "TXT"
  ttl     = 600
  records = ["v=spf1 include:amazonses.com ~all"]
}

# Route53 Record for DMARC
resource "aws_route53_record" "ses_dmarc" {
  count   = var.main_enable_route53 ? 1 : 0
  zone_id = module.main_site.route53_zone_id
  name    = "_dmarc.${var.main_domain_name}"
  type    = "TXT"
  ttl     = 600
  records = ["v=DMARC1; p=quarantine; rua=mailto:dmarc@${var.main_domain_name}"]
}

# IAM User for SMTP credentials
resource "aws_iam_user" "ses_smtp_user" {
  name = "ses-smtp-user-${var.env}"
  path = "/ses/"

  tags = {
    Name        = "SES SMTP User"
    Environment = var.env
  }
}

resource "aws_iam_user_policy" "ses_smtp_user_policy" {
  name = "ses-smtp-policy-${var.env}"
  user = aws_iam_user.ses_smtp_user.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_access_key" "ses_smtp_user" {
  user = aws_iam_user.ses_smtp_user.name
}

# IAM Role for services to send emails
resource "aws_iam_role" "ses_sending_role" {
  name = "ses-sending-role-${var.env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = [
            "lambda.amazonaws.com",
            "tasks.apprunner.amazonaws.com"
          ]
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "SES Sending Role"
    Environment = var.env
  }
}

resource "aws_iam_role_policy" "ses_sending_policy" {
  name = "ses-sending-policy"
  role = aws_iam_role.ses_sending_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ]
        Resource = "*"
      }
    ]
  })
}

# Configuration Set for tracking
resource "aws_ses_configuration_set" "main" {
  name = "schoolsmart-${var.env}"

  delivery_options {
    tls_policy = "Require"
  }
}

# Event destination for bounce/complaint tracking
resource "aws_ses_event_destination" "cloudwatch" {
  name                   = "cloudwatch-destination"
  configuration_set_name = aws_ses_configuration_set.main.name
  enabled                = true
  matching_types         = ["send", "reject", "bounce", "complaint", "delivery"]

  cloudwatch_destination {
    default_value  = "default"
    dimension_name = "ses:configuration-set"
    value_source   = "emailHeader"
  }
}

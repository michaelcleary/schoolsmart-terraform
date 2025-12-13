# AWS Amplify App
resource "aws_amplify_app" "main" {
  name       = "${var.project_name}-${var.env}"
  repository = var.amplify_repository_url

  # Monorepo configuration
  dynamic "auto_branch_creation_config" {
    for_each = var.amplify_enable_auto_branch_creation ? [1] : []
    content {
      enable_auto_build = var.amplify_enable_branch_auto_build
    }
  }

  # Build settings for Next.js in monorepo
  build_spec = var.amplify_build_spec != "" ? var.amplify_build_spec : <<-EOT
    version: 1
    applications:
      - appRoot: ${var.amplify_monorepo_app_root}
        frontend:
          phases:
            preBuild:
              commands:
                - npm ci
            build:
              commands:
                - npm run build
          artifacts:
            baseDirectory: .next
            files:
              - '**/*'
          cache:
            paths:
              - node_modules/**/*
              - .next/cache/**/*
  EOT

  # Environment variables
  # dynamic "environment_variables" {
  #   for_each = var.amplify_environment_variables
  #   content {
  #     name  = environment_variables.key
  #     value = environment_variables.value
  #   }
  # }

  # Enable auto branch creation
  enable_auto_branch_creation = var.amplify_enable_auto_branch_creation
  enable_branch_auto_build    = var.amplify_enable_branch_auto_build
  enable_branch_auto_deletion = var.amplify_enable_branch_auto_deletion

  # OAuth token for private repositories
  access_token = var.amplify_github_access_token != "" ? var.amplify_github_access_token : null

  # Custom rules for SPA routing
  dynamic "custom_rule" {
    for_each = var.amplify_custom_rules
    content {
      source = custom_rule.value.source
      target = custom_rule.value.target
      status = custom_rule.value.status
    }
  }

  # Next.js specific rewrite rules
  # Next.js on Amplify uses server-side rendering by default
  custom_rule {
    source = "/<*>"
    target = "/index.html"
    status = "404-200"
  }

  # Platform
  platform = var.amplify_platform

  tags = {
    Name        = "${var.project_name}-${var.env}"
    Environment = var.env
  }
}

# GitHub/GitLab connection (if using repository)
resource "aws_amplify_branch" "main" {
  count       = var.amplify_repository_url != "" ? 1 : 0
  app_id      = aws_amplify_app.main.id
  branch_name = var.amplify_main_branch_name

  enable_auto_build = var.amplify_enable_branch_auto_build

  environment_variables = var.amplify_branch_environment_variables

  tags = {
    Name        = "${var.project_name}-${var.env}-main"
    Environment = var.env
  }
}

# Additional branches (e.g., develop, staging)
resource "aws_amplify_branch" "additional" {
  for_each = var.amplify_additional_branches

  app_id      = aws_amplify_app.main.id
  branch_name = each.key

  enable_auto_build = lookup(each.value, "enable_auto_build", true)

  environment_variables = lookup(each.value, "environment_variables", {})

  tags = {
    Name        = "${var.project_name}-${var.env}-${each.key}"
    Environment = var.env
  }
}

# Custom domain association
resource "aws_amplify_domain_association" "main" {
  count = var.amplify_enable_custom_domain ? 1 : 0

  app_id      = aws_amplify_app.main.id
  domain_name = var.amplify_domain_name

  # Main domain
  sub_domain {
    branch_name = "amplifi-front-end"
    prefix      = "dev"
  }
  # sub_domain {
  #   branch_name = aws_amplify_branch.main[0].branch_name
  #   prefix      = var.amplify_domain_prefix
  # }

  # WWW subdomain (if enabled)
  # dynamic "sub_domain" {
  #   for_each = var.amplify_enable_www_subdomain ? [1] : []
  #   content {
  #     branch_name = aws_amplify_branch.main[0].branch_name
  #     prefix      = "www"
  #   }
  # }
  #
  # # Additional subdomains for branches
  # dynamic "sub_domain" {
  #   for_each = var.amplify_branch_subdomains
  #   content {
  #     branch_name = sub_domain.value.branch_name
  #     prefix      = sub_domain.value.prefix
  #   }
  # }

  wait_for_verification = var.amplify_wait_for_verification
}

# Route53 records for custom domain (if using custom domain and Route53)
resource "aws_route53_record" "amplify_validation" {
  count = var.amplify_enable_custom_domain && var.amplify_enable_route53 ? 1 : 0

  provider = aws.shared
  zone_id  = data.aws_route53_zone.primary.zone_id
  name     = aws_amplify_domain_association.main[0].certificate_verification_dns_record
  type     = "CNAME"
  ttl      = 300
  records  = [aws_amplify_domain_association.main[0].certificate_verification_dns_record]
}

# Webhook for triggering builds
resource "aws_amplify_webhook" "main" {
  count = var.amplify_create_webhook ? 1 : 0

  app_id      = aws_amplify_app.main.id
  branch_name = aws_amplify_branch.main[0].branch_name
  description = "Webhook for ${var.env} environment"
}

# Backend environment (for connecting to backend resources)
resource "aws_amplify_backend_environment" "main" {
  count = var.amplify_create_backend_environment ? 1 : 0

  app_id           = aws_amplify_app.main.id
  environment_name = var.env

  deployment_artifacts = var.amplify_deployment_artifacts_bucket
  stack_name          = "${var.project_name}-${var.env}-amplify-backend"
}

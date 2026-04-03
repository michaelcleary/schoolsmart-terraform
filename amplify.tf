locals {
  amplify_stage = {
    dev  = "DEVELOPMENT"
    test = "BETA"
    prod = "PRODUCTION"
  }
}

module "amplify" {
  source = "./modules/amplify"

  providers = {
    aws        = aws
    aws.shared = aws.shared
  }

  app_name                 = "${var.env}-schoolsmart-next"
  repository_url           = var.amplify_repository_url
  github_token_secret_name = var.amplify_github_token_secret_name
  branch_name              = var.amplify_branch_name
  stage               = local.amplify_stage[var.env]
  domain_name         = var.main_domain_name
  domain_prefix       = var.amplify_domain_prefix
  hosted_zone_id      = data.aws_route53_zone.primary.zone_id

  environment_variables = {
    API_BASE_URL   = "https://${var.api_domain_name}"
    SESSION_SECRET = random_password.session_secret.result
  }
}

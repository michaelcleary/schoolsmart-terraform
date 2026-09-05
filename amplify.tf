locals {
  amplify_stage = {
    dev  = "DEVELOPMENT"
    test = "BETA"
    prod = "PRODUCTION"
  }
}

# schoolsmart-terraform-kkx: this module gained `count` here with no `moved` block, which
# destroyed prod's Amplify app on its first apply after that change — Terraform read the
# address change from `module.amplify.*` (this workspace's pre-existing state, from before
# `count` was added) to `module.amplify[0].*` as destroy-then-create instead of a rename, and
# the create lost the race against its own resource names being deleted. This is a no-op for
# any workspace whose state doesn't have the old unindexed address (there is currently no
# `test` env/workspace at all), but protects any that do.
moved {
  from = module.amplify
  to   = module.amplify[0]
}

module "amplify" {
  count  = var.retire_amplify ? 0 : 1
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
    API_BASE_URL         = "https://${var.api_domain_name}"
    SESSION_SECRET       = random_password.session_secret.result
    COGNITO_USER_POOL_ID = aws_cognito_user_pool.main.id
    COGNITO_CLIENT_ID    = aws_cognito_user_pool_client.nextjs.id
    COGNITO_REGION       = var.aws_region
  }
}

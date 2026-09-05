# CloudFront distribution for the OpenNext Next.js app (schoolsmart-terraform-dl3),
# built from the same modules/site dual-origin pattern as admin_site but inverted:
# the Lambda (via the shared admin_api HTTP API — see module.lambda's
# nextjs_server_lambda and api-gateway.tf) is the default origin, and the dedicated
# static-assets bucket (nextjs-assets.tf) is an ordered-behavior origin for the path
# patterns that are actually static (_next/static/*, public/ files).
#
# Uses a temporary validation domain (var.nextjs_domain_name) until var.retire_amplify
# flips for this environment — Amplify's own CloudFront distribution claims the real
# "${amplify_domain_prefix}.${main_domain_name}" domain as an alias, and CloudFront rejects
# a second distribution claiming an alias another distribution already owns, so amplify.tf
# stops creating the Amplify app (freeing the alias) at the same time this switches domains
# (schoolsmart-terraform-yd1). Roll out dev -> test -> prod, one environment at a time.
#
# Gated behind the same flag as module.lambda's nextjs_server_lambda (enable_nextjs_lambda
# via enable_nextjs_lambda_hosting) — no point standing up a distribution whose only
# origin route (the Lambda's catch-all) doesn't exist yet.
module "nextjs_site" {
  count  = var.enable_nextjs_lambda_hosting ? 1 : 0
  source = "./modules/site"

  providers = {
    aws.virginia = aws.virginia
    aws.shared   = aws.shared
  }

  env                 = var.env
  aws_region          = var.aws_region
  domain_name         = var.retire_amplify ? "${var.amplify_domain_prefix}.${var.main_domain_name}" : var.nextjs_domain_name
  website_bucket_name = local.nextjs_assets_bucket_name
  origin_path         = "/${var.release_tag}"

  enable_cloudfront    = var.admin_enable_cloudfront
  enable_route53       = var.admin_enable_route53
  create_hosted_zone   = false
  hosted_zone_id       = data.aws_route53_zone.primary.zone_id
  use_www_subdomain    = false
  create_api_subdomain = false

  # Points the default origin at the nextjs-server Lambda's Function URL (Lambda response
  # streaming isn't invokable through API Gateway at all — see nextjs_server_lambda.tf).
  # default_origin_requires_oac = false: the AWS-documented AWS_IAM + OAC pattern returned a
  # persistent, unexplained 403 (see schoolsmart-terraform-47o) — the Function URL instead
  # uses authorization_type = NONE, secured by the shared secret sent below instead of OAC.
  enable_api_gateway         = true
  api_gateway_is_default     = true
  api_invoke_url             = module.lambda.nextjs_server_function_url_domain
  static_asset_path_patterns = var.nextjs_static_asset_path_patterns
  default_origin_verify_header_name  = "X-Origin-Verify"
  default_origin_verify_header_value = random_password.nextjs_origin_verify_secret.result

  # No explicit depends_on: api_invoke_url's reference to module.lambda's output already
  # creates a precise dependency edge.
}

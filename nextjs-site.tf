# CloudFront distribution for the OpenNext Next.js app (schoolsmart-terraform-dl3),
# built from the same modules/site dual-origin pattern as admin_site but inverted:
# the Lambda (via the shared admin_api HTTP API — see module.lambda's
# nextjs_server_lambda and api-gateway.tf) is the default origin, and the dedicated
# static-assets bucket (nextjs-assets.tf) is an ordered-behavior origin for the path
# patterns that are actually static (_next/static/*, public/ files).
#
# Uses a temporary validation domain (var.nextjs_domain_name) rather than the real
# "${amplify_domain_prefix}.${main_domain_name}" domain — Amplify's own CloudFront
# distribution already claims that domain as an alias, and CloudFront rejects a second
# distribution claiming an alias another distribution already owns. The real domain
# cutover (removing Amplify's alias, pointing this distribution's aliases at it instead)
# is schoolsmart-terraform-yd1, once this has been validated end-to-end in dev.
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
  domain_name         = var.nextjs_domain_name
  website_bucket_name = local.nextjs_assets_bucket_name
  origin_path         = "/${var.release_tag}"

  enable_cloudfront    = var.admin_enable_cloudfront
  enable_route53       = var.admin_enable_route53
  create_hosted_zone   = false
  hosted_zone_id       = data.aws_route53_zone.primary.zone_id
  use_www_subdomain    = false
  create_api_subdomain = false

  # TRANSITIONAL (step 1 of 3, see nextjs_server_lambda.tf): still pointed at the API
  # Gateway custom domain here — moving straight to api_invoke_url =
  # module.lambda.nextjs_server_function_url_domain in the same apply that removes the old
  # API Gateway route/integration/permission causes a Terraform dependency cycle (the
  # distribution's output-reference dependency on module.lambda's "close", combined with
  # this distribution's own resources being depended on by the api-gateway destroy
  # ordering). Step 2 repoints this at the Function URL (while the old API Gateway wiring
  # still exists, so nothing destroys yet); step 3 then removes the old wiring cleanly.
  enable_api_gateway         = true
  api_gateway_is_default     = true
  api_invoke_url             = aws_apigatewayv2_domain_name.web_service_api_domain_name.domain_name
  static_asset_path_patterns = var.nextjs_static_asset_path_patterns

  depends_on = [module.lambda]
}

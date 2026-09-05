env = "prod"

aws_account = "923305906880"
shared_services_account_id = "756208870582"
management_account_id = "548144873869"

aws_region = "eu-west-2"
admin_domain_name = "admin.schoolsmart.co.uk"
api_domain_name = "api.schoolsmart.co.uk"

# Main site variables
main_domain_name       = "schoolsmart.co.uk"
main_enable_cloudfront = true
main_enable_route53    = true
main_create_hosted_zone = true
main_use_www_subdomain = true

# Admin site variables
admin_enable_cloudfront = true
admin_enable_route53    = true
admin_create_hosted_zone = false
admin_use_www_subdomain = false

# schoolsmart-terraform-kkx: bumped to a previously-verified dev release (dev's release_tag
# before its most recent bump) so prod picks up that same App Runner image + admin_site
# static assets, alongside enabling OpenNext Lambda hosting below (test skipped — going
# straight dev -> prod for this rollout).
release_tag = "f39246e1"

# schoolsmart-terraform-kkx incident: prod's first apply through this workflow hit a latent
# bug in amplify.tf (module.amplify gained `count` with no `moved` block in the yd1 PR) that
# destroyed prod's Amplify app, its IAM roles, and the app.schoolsmart.co.uk DNS record, then
# failed to recreate them (name conflict racing its own deletion). Rather than recreate
# Amplify, retiring it outright and cutting the real domain straight over to the OpenNext
# CloudFront distribution below — see retire_amplify.
create_github_oidc_provider = false # dev's workspace already owns this global (management-
# account) resource; prod trying to create it too 409s instead of being a no-op.

# Amplify / NextJS
amplify_repository_url           = "https://github.com/michaelcleary/schoolsmart-admin"
amplify_branch_name              = "master"
amplify_domain_prefix            = "app"
amplify_github_token_secret_name = "amplify/github-app-token"

# OpenNext Lambda + CloudFront (schoolsmart-terraform-dl3) — see nextjs-site.tf. Unused now
# that retire_amplify is true below (domain_name becomes app.schoolsmart.co.uk instead); left
# set as a record of what this env used to validate on before the kkx incident forced an
# earlier-than-planned cutover.
nextjs_domain_name = "next-app.schoolsmart.co.uk"

# schoolsmart-terraform-kkx: schoolsmart-admin's OpenNext build for release_tag=f39246e1 is
# already confirmed uploaded to the shared schoolsmart-lambda / schoolsmart-nextjs-assets
# buckets (same shared buckets dev reads/writes — see nextjs-assets.tf), so it's safe to flip
# this on for prod without a separate artifact upload step. Creates the Lambda server + prod's
# own CloudFront distribution — on the real app.schoolsmart.co.uk domain now that retire_amplify
# is true below, since Amplify no longer exists to hold that alias.
enable_nextjs_lambda_hosting = true

# schoolsmart-terraform-kkx: Amplify was destroyed (see incident note above) with no working
# replacement, so there's nothing left to validate against on a temporary domain — cutting
# app.schoolsmart.co.uk straight over to the OpenNext CloudFront distribution instead of
# leaving prod's real domain dark. Stops creating module.amplify (already gone in AWS; this
# just brings config in line with reality) and repoints nextjs_site's domain_name at the real
# domain. Verify immediately after apply: bare '/' redirect, SSR render, S3 static asset,
# Cognito login.
retire_amplify = true

# schoolsmart-terraform-kkx: prod's real distribution now exists (confirmed end-to-end after
# the Amplify cutover above) — tightens the nextjs-server Lambda Function URL's CloudFront
# invoke permission from aws:SourceAccount to aws:SourceArn (see main.tf's lookup(...) into
# module.lambda). The matching entry also needs adding to dev.tfvars's
# nextjs_cloudfront_distribution_arns to tighten the shared nextjs-assets bucket policy — dev
# is the owning workspace for that resource.
nextjs_cloudfront_distribution_arns = {
  prod = "arn:aws:cloudfront::923305906880:distribution/EJQ952L3GQXG2"
}

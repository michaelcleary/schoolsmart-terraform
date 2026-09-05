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

# schoolsmart-terraform-kkx: bumped to match dev's current release_tag so prod picks up
# the same App Runner image + admin_site static assets dev is running, alongside enabling
# OpenNext Lambda hosting below (test skipped — going straight dev -> prod for this rollout).
release_tag = "f39246e1"

# Amplify / NextJS
amplify_repository_url           = "https://github.com/michaelcleary/schoolsmart-admin"
amplify_branch_name              = "master"
amplify_domain_prefix            = "app"
amplify_github_token_secret_name = "amplify/github-app-token"

# OpenNext Lambda + CloudFront (schoolsmart-terraform-dl3) — temporary validation domain,
# see nextjs-site.tf. Not the real app.schoolsmart.co.uk domain until yd1 cuts over.
nextjs_domain_name = "next-app.schoolsmart.co.uk"

# schoolsmart-terraform-kkx: schoolsmart-admin's OpenNext build for release_tag=ef3c4727 is
# already confirmed uploaded to the shared schoolsmart-lambda / schoolsmart-nextjs-assets
# buckets (same shared buckets dev reads/writes — see nextjs-assets.tf), so it's safe to flip
# this on for prod without a separate artifact upload step. Creates the Lambda server + prod's
# own CloudFront distribution on the temporary nextjs_domain_name above; retire_amplify stays
# false here until this is verified end-to-end (bare '/' redirect, SSR render, S3 static asset,
# Cognito login) — the real domain cutover is a separate follow-up, same as dev's yd1.
enable_nextjs_lambda_hosting = true

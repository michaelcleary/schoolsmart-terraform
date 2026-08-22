env = "dev"

aws_account = "099635824433"
shared_services_account_id = "756208870582"
management_account_id = "548144873869"

aws_region = "eu-west-2"
admin_domain_name = "dev-admin.schoolsmart.co.uk"
api_domain_name = "dev-api.schoolsmart.co.uk"

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

email_override = "it@schoolsmart.co.uk"

release_tag = "5d1864e7"

# Amplify / NextJS
amplify_repository_url           = "https://github.com/michaelcleary/schoolsmart-admin"
amplify_branch_name              = "master"
amplify_domain_prefix            = "dev-app"
amplify_github_token_secret_name = "amplify/github-app-token"

# Shared cross-env buckets (see nextjs-assets.tf) — dev is the "owning" workspace that
# creates them and writes their CloudFront-read bucket policies; test/prod just read
# them via a data source.
create_shared_buckets = true
env_account_ids = {
  dev  = "099635824433"
  test = "117622437145"
  prod = "923305906880"
}

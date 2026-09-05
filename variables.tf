variable "project_name" {
  default = "SchoolSmart Admin"
}

variable "env" {
  description = "Environment name"
}

variable "aws_account" {
}

variable "shared_services_account_id" {
}

variable "aws_region" {
  description = "AWS region for resources"
}

# Main site variables
variable "main_domain_name" {
  description = "The domain name for the main site"
}

variable "main_website_bucket_name" {
  description = "The name of the bucket where the main site static resources are kept"
  default     = "schoolsmart-website"
}

variable "main_enable_cloudfront" {
  description = "Enable CloudFront distribution for the main site"
}

variable "main_enable_route53" {
  description = "Enable Route 53 for the main site domain"
}

variable "main_create_hosted_zone" {
  description = "Whether to create a new hosted zone for the main site"
}

variable "main_use_www_subdomain" {
  description = "Whether to create a www subdomain for the main site"
}

variable "admin_domain_name" {
  description = "The domain name for the admin site"
}

variable "api_domain_name" {
  description = "The domain name for the API"
}

variable "admin_website_bucket_name" {
  description = "The name of the bucket where the admin site static resources are kept"
  default     = "schoolsmart-admin-website"
}

variable "admin_enable_cloudfront" {
  description = "Enable CloudFront distribution for the admin site"
}

variable "admin_enable_route53" {
  description = "Enable Route 53 for the admin site domain"
}

variable "admin_create_hosted_zone" {
  description = "Whether to create a new hosted zone for the admin site"
}

variable "admin_use_www_subdomain" {
  description = "Whether to create a www subdomain for the admin site"
}

# Shared cross-env bucket variables (see nextjs-assets.tf)
variable "create_shared_buckets" {
  description = "Whether this workspace owns creation of cross-env shared-services-account buckets (e.g. the Next.js static assets bucket). Set true in exactly one env's tfvars (dev) — the other workspaces reference the bucket via a data source instead of trying to create it too."
  type        = bool
  default     = false
}

variable "env_account_ids" {
  description = "Map of env name -> AWS account ID. Only read by the owning workspace (create_shared_buckets = true) to scope shared-bucket CloudFront read policies to each env's account. Unused (default {}) in non-owning workspaces."
  type        = map(string)
  default     = {}
}

variable "nextjs_cloudfront_distribution_arns" {
  description = "Map of env name -> that env's OpenNext CloudFront distribution ARN (schoolsmart-terraform-dl3/6rk), once it exists. Only read by the owning workspace (create_shared_buckets = true) to scope the nextjs-assets bucket policy to aws:SourceArn for that env. Envs with no entry here fall back to the looser aws:SourceAccount condition."
  type        = map(string)
  default     = {}
}

# App Runner variables
variable "app_runner_ecr_repo_url" {
  description = "The URL of the ECR repository containing the Docker image"
  type        = string
  default     = "756208870582.dkr.ecr.eu-west-2.amazonaws.com/schoolsmart-admin"
}

variable "release_tag" {
  description = "The github sha for the release"
  type        = string
}

variable "app_runner_port" {
  description = "The port the app server listens on"
  type        = number
  default     = 8080
}

variable "app_runner_cpu" {
  description = "The amount of CPU units for the app server"
  type        = string
  default     = "256"
}

variable "app_runner_memory" {
  description = "The amount of memory for the app server"
  type        = string
  default     = "512"
}

variable "app_runner_auto_deployments_enabled" {
  description = "Whether to automatically deploy new images"
  type        = bool
  default     = true
}

variable "app_runner_enable_custom_domain" {
  description = "Whether to enable a custom domain for the App Runner service"
  type        = bool
  default     = false
}

variable "app_runner_domain_name" {
  description = "The custom domain name for the App Runner service"
  type        = string
  default     = ""
}

variable "app_runner_enable_www_subdomain" {
  description = "Whether to enable www subdomain for the App Runner service"
  type        = bool
  default     = false
}

variable "app_runner_api_prefix" {
  description = "The API path prefix that should be routed to the app server"
  type        = string
  default     = "/api"
}

variable "management_account_id" {
  description = "The AWS account ID of the management account"
  type        = string
}

variable "management_account_role_name" {
  description = "The name of the role to assume in the management account"
  type        = string
  default     = "OrganizationAccountAccessRole"
}

variable "account_email" {
  description = "The email address for the new AWS account"
  type        = string
  default     = ""
}

variable "create_github_oidc_provider" {
  description = "Create the GitHub OIDC provider and CI role in the management account. Must be true in at least one environment to bootstrap CI auth. Safe to leave true in all environments — the resources are idempotent."
  type        = bool
  default     = true
}

variable "create_account" {
  description = "Whether to create a new AWS account for this environment"
  type        = bool
  default     = false
}

variable "email_override" {
  description = "Override email for non-production environment"
  type        = string
  default     = ""
}

# Amplify / NextJS variables
variable "amplify_repository_url" {
  description = "GitHub repository URL for the NextJS monorepo"
  type        = string
}

variable "amplify_github_token_secret_name" {
  description = "Secrets Manager secret name holding the GitHub App installation token for Amplify"
  type        = string
}

variable "amplify_branch_name" {
  description = "Git branch to deploy to this environment"
  type        = string
  default     = "main"
}

variable "amplify_domain_prefix" {
  description = "Subdomain prefix for the NextJS app (e.g. 'app', 'dev-app', 'test-app')"
  type        = string
}

# OpenNext Lambda + CloudFront hosting (schoolsmart-terraform-dl3), running alongside
# Amplify during the transition. Amplify's own CloudFront distribution already claims
# "${amplify_domain_prefix}.${main_domain_name}" as an alias, and CloudFront rejects a
# second distribution claiming an alias another distribution already owns — so this uses
# its own temporary domain until schoolsmart-terraform-yd1 retires Amplify and cuts the
# real domain over.
variable "nextjs_domain_name" {
  description = "Temporary validation domain for the OpenNext CloudFront distribution (e.g. 'next-dev-app.schoolsmart.co.uk'). Superseded by amplify_domain_prefix's domain once yd1 cuts over."
  type        = string
  default     = ""
}

# schoolsmart-terraform-yd1: retires Amplify for this environment once its OpenNext
# CloudFront distribution (nextjs-site.tf) has been validated end-to-end on its temporary
# domain. Flipping this to true stops creating module.amplify (freeing up the
# "${amplify_domain_prefix}.${main_domain_name}" alias) and repoints nextjs_site's domain_name
# at that real domain instead of the temporary validation one. Roll out dev -> test -> prod,
# one environment at a time, not all at once — this is a DNS cutover.
variable "retire_amplify" {
  description = "Cut this environment's real Next.js domain over from Amplify to the OpenNext CloudFront distribution, and stop creating the Amplify app."
  type        = bool
  default     = false
}

# Off by default: aws_lambda_function.function fails to create if s3_key doesn't exist
# yet in lambda_code_bucket, which would otherwise fail *every* apply to this workspace
# (terraform apply is all-or-nothing) until schoolsmart-admin's OpenNext build is landing
# real nextjs-server.zip / .open-next/assets uploads for release_tag. Flip to true once
# that's confirmed for the release_tag currently set in <env>.tfvars.
variable "enable_nextjs_lambda_hosting" {
  description = "Create the OpenNext Lambda server + its CloudFront distribution. Requires nextjs-server.zip to already exist at s3://<lambda_code_bucket>/<release_tag>/nextjs-server.zip."
  type        = bool
  default     = false
}

variable "nextjs_static_asset_path_patterns" {
  description = "CloudFront path patterns routed to the OpenNext static-assets S3 origin instead of the Lambda server origin"
  type        = list(string)
  default     = ["/_next/static/*", "/favicon.ico", "/robots.txt"]
}
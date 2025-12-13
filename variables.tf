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

# App Runner variables
variable "app_runner_ecr_repo_url" {
  description = "The URL of the ECR repository containing the Docker image"
  type        = string
  default     = "756208870582.dkr.ecr.eu-west-2.amazonaws.com/schoolsmart-admin"
}

variable "app_runner_image_tag" {
  description = "The tag of the Docker image to deploy"
  type        = string
  default     = "latest"
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

variable "client_version" {
  description = "The version of the client app to deploy"
  type = number
}

# AWS Amplify variables
variable "amplify_repository_url" {
  description = "The repository URL for the Amplify app (leave empty for manual deploys)"
  type        = string
  default     = ""
}

variable "amplify_github_access_token" {
  description = "GitHub personal access token for private repositories"
  type        = string
  default     = ""
  sensitive   = true
}

variable "amplify_monorepo_app_root" {
  description = "The root directory of the app in a monorepo (e.g., 'apps/web')"
  type        = string
  default     = ""
}

variable "amplify_main_branch_name" {
  description = "The main branch name for Amplify"
  type        = string
  default     = "main"
}

variable "amplify_build_spec" {
  description = "Custom build specification for Amplify (leave empty for default)"
  type        = string
  default     = ""
}

variable "amplify_environment_variables" {
  description = "Environment variables for Amplify app"
  type        = map(string)
  default     = {}
}

variable "amplify_branch_environment_variables" {
  description = "Environment variables specific to the main branch"
  type        = map(string)
  default     = {}
}

variable "amplify_enable_auto_branch_creation" {
  description = "Enable automatic branch creation in Amplify"
  type        = bool
  default     = false
}

variable "amplify_enable_branch_auto_build" {
  description = "Enable automatic builds for branches"
  type        = bool
  default     = true
}

variable "amplify_enable_branch_auto_deletion" {
  description = "Enable automatic deletion of branches"
  type        = bool
  default     = false
}

variable "amplify_custom_rules" {
  description = "Custom rewrite and redirect rules for Amplify"
  type = list(object({
    source = string
    target = string
    status = string
  }))
  default = []
}

variable "amplify_platform" {
  description = "Platform type for Amplify app"
  type        = string
  default     = "WEB"
}

variable "amplify_additional_branches" {
  description = "Additional branches to create in Amplify"
  type = map(object({
    enable_auto_build      = optional(bool, true)
    environment_variables  = optional(map(string), {})
  }))
  default = {}
}

variable "amplify_enable_custom_domain" {
  description = "Enable custom domain for Amplify app"
  type        = bool
  default     = false
}

variable "amplify_domain_name" {
  description = "Custom domain name for Amplify app"
  type        = string
  default     = ""
}

variable "amplify_domain_prefix" {
  description = "Domain prefix for the main branch (empty for apex domain)"
  type        = string
  default     = ""
}

variable "amplify_enable_www_subdomain" {
  description = "Enable www subdomain for Amplify app"
  type        = bool
  default     = false
}

variable "amplify_branch_subdomains" {
  description = "Subdomain mappings for additional branches"
  type = list(object({
    branch_name = string
    prefix      = string
  }))
  default = []
}

variable "amplify_wait_for_verification" {
  description = "Wait for domain verification before completing"
  type        = bool
  default     = false
}

variable "amplify_enable_route53" {
  description = "Create Route53 records for Amplify domain"
  type        = bool
  default     = false
}

variable "amplify_create_webhook" {
  description = "Create a webhook for triggering builds"
  type        = bool
  default     = false
}

variable "amplify_create_backend_environment" {
  description = "Create backend environment for Amplify"
  type        = bool
  default     = false
}

variable "amplify_deployment_artifacts_bucket" {
  description = "S3 bucket for Amplify deployment artifacts"
  type        = string
  default     = ""
}
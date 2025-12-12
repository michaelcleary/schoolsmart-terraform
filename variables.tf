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
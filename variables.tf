variable "env" {
  description = "Environment name"
  default     = "dev"
}

variable "vpc" {
  default = "vpc-0acf87d14d388455a"
}

variable "aws_account" {
  default = "756208870582"
}

variable "aws_region" {
  description = "AWS region for resources"
  default     = "eu-west-2"
}

# Main site variables
variable "main_domain_name" {
  description = "The domain name for the main site"
  default     = "schoolsmart.co.uk"
}

variable "main_website_bucket_name" {
  description = "The name of the bucket where the main site static resources are kept"
  default     = "schoolsmart-website"
}

variable "main_enable_cloudfront" {
  description = "Enable CloudFront distribution for the main site"
  default     = true
}

variable "main_enable_route53" {
  description = "Enable Route 53 for the main site domain"
  default     = true
}

variable "main_create_hosted_zone" {
  description = "Whether to create a new hosted zone for the main site"
  default     = true
}

variable "main_use_www_subdomain" {
  description = "Whether to create a www subdomain for the main site"
  default     = true
}

# Admin site variables
variable "admin_domain_name" {
  description = "The domain name for the admin site"
  default     = "test-admin.schoolsmart.co.uk"
}

variable "admin_website_bucket_name" {
  description = "The name of the bucket where the admin site static resources are kept"
  default     = "schoolsmart-admin-website"
}

variable "admin_enable_cloudfront" {
  description = "Enable CloudFront distribution for the admin site"
  default     = true
}

variable "admin_enable_route53" {
  description = "Enable Route 53 for the admin site domain"
  default     = true
}

variable "admin_create_hosted_zone" {
  description = "Whether to create a new hosted zone for the admin site"
  default     = false
}

variable "admin_use_www_subdomain" {
  description = "Whether to create a www subdomain for the admin site"
  default     = false
}

variable "lambda_bucket_name" {
  description = "The name of the bucket where the lambda functions are kept"
  default     = "schoolsmart-lambda"
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
  default     = "1 vCPU"
}

variable "app_runner_memory" {
  description = "The amount of memory for the app server"
  type        = string
  default     = "2 GB"
}

variable "app_runner_environment_variables" {
  description = "Environment variables for the app server"
  type        = map(string)
  default     = {
    NODE_ENV   = "dev"
    PORT       = "8080"
    S3_BUCKET = "schoolsmart-invoice-test-bucket"
    S3_REGION = "eu-west-2"
    JWT_SECRET = "8807425C-DA90-4BA3-BA85-AE4CEC7FBDEC"
  }
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

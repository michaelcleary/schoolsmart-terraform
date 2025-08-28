variable "env" {
  description = "Environment name"
  default     = "dev"
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

# Shared resources variables
variable "lambda_bucket_name" {
  description = "The name of the bucket where the lambda functions are kept"
  default     = "schoolsmart-lambda"
}


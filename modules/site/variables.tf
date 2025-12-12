variable "env" {
  description = "Environment name"
  type        = string
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
}

variable "domain_name" {
  description = "The domain name to be used for the S3 bucket and CloudFront"
  type        = string
}

variable "website_bucket_name" {
  description = "The name of the bucket where the static resources are kept"
  type        = string
}

variable "origin_path" {
  description = "The path in the origin bucket"
  type        = string
  default = ""
}

variable "enable_cloudfront" {
  description = "Enable CloudFront distribution for the S3 website"
  type        = bool
  default     = true
}

variable "enable_route53" {
  description = "Enable Route 53 for custom domain"
  type        = bool
  default     = true
}

variable "create_hosted_zone" {
  description = "Whether to create a new hosted zone or use an existing one"
  type        = bool
  default     = true
}

variable "hosted_zone_id" {
  description = "ID of an existing Route53 hosted zone to use (if create_hosted_zone is false)"
  type        = string
  default     = ""
}

variable "use_www_subdomain" {
  description = "Whether to create a www subdomain"
  type        = bool
  default     = true
}

variable "create_api_subdomain" {
  description = "Whether to create an API subdomain"
  type        = bool
  default     = false
}

variable "enable_api_gateway" {
  description = "Is API gateway enabled"
  type        = bool
  default     = false
}

variable "api_invoke_url" {
  description = "URL for Gateway"
  type        = string
  default     = ""
}
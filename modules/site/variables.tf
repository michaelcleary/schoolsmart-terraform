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
  default     = ""
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

variable "api_gateway_is_default" {
  description = <<-EOT
    Inverts the dual-origin pattern: when true, the API Gateway (Lambda) origin becomes
    the default cache behavior instead of S3, for SSR apps where most paths need to hit
    the origin server. The /auth/*, /api/* ordered behaviors (which assume API Gateway is
    the secondary origin) are skipped, and static_asset_path_patterns are used instead to
    route known static prefixes to S3. Also disables the SPA-style 403/404 -> /index.html
    error rewriting, since that doesn't apply to a server-rendered app.
  EOT
  type        = bool
  default     = false
}

variable "static_asset_path_patterns" {
  description = "Path patterns routed to the S3 origin as ordered cache behaviors. Only used when api_gateway_is_default is true."
  type        = list(string)
  default     = []
}

variable "default_origin_requires_oac" {
  description = "Whether the default (API Gateway / Lambda Function URL) origin needs SigV4-signed invocation via a CloudFront Origin Access Control of type 'lambda' — true for a Lambda Function URL with AWS_IAM auth (api_invoke_url pointed at the function URL's domain), false for a plain API Gateway custom origin (which doesn't use OAC)."
  type        = bool
  default     = false
}

variable "default_origin_verify_header_name" {
  description = "Name of a single custom header CloudFront sends to the default (API Gateway / Lambda Function URL) origin on every request — e.g. a shared secret a NONE-auth Lambda Function URL's own code checks, since it has no IAM-based access control of its own. Null skips sending one."
  type        = string
  default     = null
}

variable "default_origin_verify_header_value" {
  description = "Value of default_origin_verify_header_name. Deliberately a single name/value pair (not a map/list of headers): Terraform 1.9 (pinned in CI) rejects for_each over ANY sensitive-tainted collection regardless of its type (map, object, and list all hit \"Cannot use a <type> value in for_each\" — the error names the resolved type, not the real cause). Iterating over a fixed [1]/[] literal instead and referencing this sensitive value only inside the dynamic block's content sidesteps that entirely."
  type        = string
  default     = null
  sensitive   = true
}
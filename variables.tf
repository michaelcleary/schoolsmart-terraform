variable "env" {
  default = "dev"
}

variable "aws_region" {
  default = "eu-west-2"
}

variable "domain_name" {
  description = "The domain name to be used for the S3 bucket and CloudFront."
  default     = "schoolsmart.co.uk"
}

variable "website_bucket_name" {
  description = "The name of the bucket where the static resources are kept."
  default     = "schoolsmart-website"
}

variable "lambda_bucket_name" {
  description = "The name of the bucket where the lambda functions are kept."
  default     = "schoolsmart-lambda"
}

variable "enable_cloudfront" {
  description = "Enable CloudFront distribution for the S3 website."
  default     = true
}

variable "enable_route53" {
  description = "Enable Route 53 for custom domain."
  default     = true
}


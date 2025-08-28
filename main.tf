provider "aws" {
  region = var.aws_region
}

# Provider for ACM certificates (must be in us-east-1 for CloudFront)
provider "aws" {
  alias  = "virginia"
  region = "us-east-1"
}

# Deploy the main site
module "main_site" {
  source = "./modules/site"
  
  providers = {
    aws.virginia = aws.virginia
  }

  env                   = var.env
  aws_region            = var.aws_region
  domain_name           = var.main_domain_name
  website_bucket_name   = var.main_website_bucket_name
  enable_cloudfront     = var.main_enable_cloudfront
  enable_route53        = var.main_enable_route53
  create_hosted_zone    = var.main_create_hosted_zone
  use_www_subdomain     = var.main_use_www_subdomain
  create_api_subdomain  = false  # Set to true when API Gateway is configured
}

# Deploy the admin site
module "admin_site" {
  source = "./modules/site"

  providers = {
    aws.virginia = aws.virginia
  }

  env                   = var.env
  aws_region            = var.aws_region
  domain_name           = var.admin_domain_name
  website_bucket_name   = var.admin_website_bucket_name
  origin_path           = "/v1/browser/browser"
  enable_cloudfront     = var.admin_enable_cloudfront
  enable_route53        = var.admin_enable_route53
  create_hosted_zone    = var.admin_create_hosted_zone
  hosted_zone_id        = module.main_site.route53_zone_id
  use_www_subdomain     = var.admin_use_www_subdomain
  create_api_subdomain  = false
}

# Create a shared S3 bucket for Lambda functions
resource "aws_s3_bucket" "lambda_code_bucket" {
  bucket = var.lambda_bucket_name

  tags = {
    Name        = "LambdaCodeBucket"
    Environment = var.env
  }
}
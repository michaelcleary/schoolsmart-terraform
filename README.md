# SchoolSmart Terraform Infrastructure

This repository contains Terraform code for deploying the SchoolSmart web application infrastructure on AWS.

## Architecture

The infrastructure is modularized to support multiple sites with their own domains, following the same pattern:

- Each site has its own S3 bucket for static website hosting
- CloudFront distribution for content delivery
- ACM certificates for HTTPS
- Route53 records for DNS

The infrastructure also includes shared resources:
- Lambda functions for backend processing
- DynamoDB tables for data storage
- API Gateway for API endpoints

## Sites

The infrastructure currently supports two sites:

1. **Main Site**
   - Domain: schoolsmart.co.uk
   - Features: www subdomain, API subdomain (when enabled)

2. **Admin Site**
   - Domain: test-admin.schoolsmart.co.uk
   - Features: Uses the same Route53 hosted zone as the main site

## Usage

### Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform v1.0.0 or later

### Initialization

Initialize the Terraform configuration:

```bash
terraform init
```

### Planning

Review the changes that will be applied:

```bash
terraform plan
```

### Applying Changes

Apply the changes to create or update the infrastructure:

```bash
terraform apply
```

### Destroying Infrastructure

To destroy the infrastructure:

```bash
terraform destroy
```

## Configuration

The infrastructure can be configured through variables in `variables.tf`. Key variables include:

### Main Site Variables

- `main_domain_name` - The domain name for the main site (default: "schoolsmart.co.uk")
- `main_website_bucket_name` - The S3 bucket name for the main site (default: "schoolsmart-website")
- `main_enable_cloudfront` - Enable CloudFront for the main site (default: true)
- `main_enable_route53` - Enable Route53 for the main site (default: true)
- `main_create_hosted_zone` - Create a new hosted zone for the main site (default: true)
- `main_use_www_subdomain` - Create a www subdomain for the main site (default: true)

### Admin Site Variables

- `admin_domain_name` - The domain name for the admin site (default: "test-admin.schoolsmart.co.uk")
- `admin_website_bucket_name` - The S3 bucket name for the admin site (default: "schoolsmart-admin-website")
- `admin_enable_cloudfront` - Enable CloudFront for the admin site (default: true)
- `admin_enable_route53` - Enable Route53 for the admin site (default: true)
- `admin_create_hosted_zone` - Create a new hosted zone for the admin site (default: false)
- `admin_use_www_subdomain` - Create a www subdomain for the admin site (default: false)

### Shared Resources Variables

- `lambda_bucket_name` - The S3 bucket name for Lambda functions (default: "schoolsmart-lambda")

## Adding a New Site

To add a new site:

1. Add new variables in `variables.tf` for the new site
2. Add a new module call in `main.tf` for the new site
3. Add new outputs in `outputs.tf` for the new site

Example module call for a new site:

```hcl
module "new_site" {
  source = "./modules/site"

  env                   = var.env
  aws_region            = var.aws_region
  domain_name           = var.new_site_domain_name
  website_bucket_name   = var.new_site_website_bucket_name
  enable_cloudfront     = var.new_site_enable_cloudfront
  enable_route53        = var.new_site_enable_route53
  create_hosted_zone    = var.new_site_create_hosted_zone
  hosted_zone_id        = var.new_site_create_hosted_zone ? "" : module.main_site.route53_zone_id
  use_www_subdomain     = var.new_site_use_www_subdomain
  create_api_subdomain  = var.new_site_create_api_subdomain
}
```
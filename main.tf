# Provider for ACM certificates (must be in us-east-1 for CloudFront)
provider "aws" {
  alias  = "virginia"
  region = "us-east-1"
  assume_role {
    role_arn = local.account_role_arn
  }
  # assume_role {
  #   role_arn = "arn:aws:iam::${var.shared_services_account_id}:role/${var.management_account_role_name}"
  # }
}

provider "aws" {
  alias  = "management"
  region = var.aws_region
}

provider "aws" {
  alias  = "shared"
  region = var.aws_region
  assume_role {
    role_arn = "arn:aws:iam::${var.shared_services_account_id}:role/${var.management_account_role_name}"
  }
}

provider "aws" {
  region = var.aws_region

  assume_role {
    role_arn = local.account_role_arn
  }

  default_tags {
    tags = {
      Environment = terraform.workspace
      ManagedBy   = "Terraform"
      Project     = var.project_name
    }
  }
}

data "aws_ecr_repository" "shared_ecr" {
  provider = aws.shared
  name = "schoolsmart-admin"
}

# resource "aws_ecr_repository_policy" "shared_ecr_policy" {
#   provider   = aws.shared
#   repository = data.aws_ecr_repository.shared_ecr.name
#
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Sid    = "AllowWorkloadAccountsPull"
#         Effect = "Allow"
#         Principal = {
#           AWS = [ "arn:aws:iam::${var.aws_account}:root" ]
#         }
#         Action = [
#           "ecr:GetDownloadUrlForLayer",
#           "ecr:BatchGetImage",
#           "ecr:BatchCheckLayerAvailability"
#         ]
#       },
#       {
#         Sid    = "AllowWorkloadAccountsAuth"
#         Effect = "Allow"
#         Principal = {
#           AWS = [ "arn:aws:iam::${var.aws_account}:root" ]
#         }
#         Action = [
#           "ecr:GetAuthorizationToken"
#         ]
#       }
#     ]
#   })
# }

data "aws_route53_zone" "primary" {
  provider = aws.shared
  name  = var.main_domain_name
}

# Create a shared S3 bucket for Lambda functions
data "aws_s3_bucket" "lambda_code_bucket" {
  provider = aws.shared
  bucket = local.lambda_bucket_name
}

resource "aws_s3_bucket" "invoice_bucket" {
  bucket = local.invoice_bucket_name

  tags = {
    Name        = "LambdaCodeBucket"
    Environment = var.env
  }
}

resource "aws_s3_bucket" "xero_auth_bucket" {
  bucket = local.xero_auth_bucket_name

  tags = {
    Name        = "XeroAuthBucket"
    Environment = var.env
  }
}

resource "random_string" "jwt_secret" {
  length  = 20
  special = false
}

# Deploy the main site
# module "main_site" {
#   source = "./modules/site"
#
#   providers = {
#     aws.virginia = aws.virginia
#     aws.shared = aws.shared
#   }
#
#   env                   = var.env
#   aws_region            = var.aws_region
#   domain_name           = var.main_domain_name
#   website_bucket_name   = var.main_website_bucket_name
#   enable_cloudfront     = var.main_enable_cloudfront
#   enable_route53        = var.main_enable_route53
#   create_hosted_zone    = var.main_create_hosted_zone
#   use_www_subdomain     = var.main_use_www_subdomain
#   create_api_subdomain  = false
# }

# Deploy the admin site
module "admin_site" {
  source = "./modules/site"

  providers = {
    aws.virginia = aws.virginia
    aws.shared = aws.shared
  }

  env                   = var.env
  aws_region            = var.aws_region
  domain_name           = var.admin_domain_name
  website_bucket_name   = var.admin_website_bucket_name
  origin_path           = "/v${var.client_version}"
  enable_cloudfront     = var.admin_enable_cloudfront
  enable_route53        = var.admin_enable_route53
  create_hosted_zone    = var.admin_create_hosted_zone
  hosted_zone_id        = data.aws_route53_zone.primary.zone_id
  use_www_subdomain     = var.admin_use_www_subdomain
  create_api_subdomain  = true
  enable_api_gateway    = true
  api_invoke_url        = aws_apigatewayv2_domain_name.web_service_api_domain_name.domain_name
}

module "database" {
  source = "./dynamodb"
  env    = var.env
}

module "lambda" {
  source = "./lambda"
  env                        = var.env
  aws_account                = var.aws_account
  aws_region                 = var.aws_region
  lambda_code_bucket         = data.aws_s3_bucket.lambda_code_bucket
  auth_bucket                = aws_s3_bucket.xero_auth_bucket
  invoices_table_stream_arn  = module.database.invoices_table_stream_arn
  api_gateway_v2_api_id      = aws_apigatewayv2_api.admin_api.id
  email_override             = var.email_override
  shared_services_account_id = var.shared_services_account_id
}

locals {
  # IAM role ARNs to assume for each workspace
  account_role_arn = "arn:aws:iam::${var.aws_account}:role/OrganizationAccountAccessRole"
  lambda_bucket_name = "schoolsmart-lambda"
  invoice_bucket_name = "schoolsmart-${var.env}-invoices"
  xero_auth_bucket_name = "schoolsmart-${var.env}-xero-auth"
  app_runner_env_vars = {
      NODE_ENV = var.env
      S3_REGION = var.aws_region
      S3_BUCKET = local.invoice_bucket_name
      SHARED_ACCOUNT = var.shared_services_account_id
      JWT_SECRET = random_string.jwt_secret.id
      PORT = 8080
      EMAIL_OVERRIDE = var.email_override
  }
}

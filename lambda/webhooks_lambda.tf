module "webhooks_lambda" {
  source = "../modules/lambda"

  function_name = "xero-webhook"

  s3_bucket = var.lambda_code_bucket.bucket
  s3_key    = "xero-webhook/20251213-155815-80f5ff160469467a75e6bed8951f73343dc38f93.zip"

  env = var.env

  environment_variables = {
    NODE_ENV         = var.env
    AUTH_BUCKET_NAME = var.auth_bucket
  }

  aws_region     = var.aws_region
  aws_account_id = var.aws_account

  # API Gateway V2 Trigger
  api_gateway_v2_config = {
    api_id     = var.api_gateway_v2_api_id
    route_keys = ["POST /webhooks"]
  }

  # IAM Permissions
  iam_policy_statements = [
    {
      effect = "Allow"
      actions = [
        "ssm:GetParameter",
        "ssm:GetParameters",
        "ssm:GetParametersByPath"
      ]
      resources = [
        "arn:aws:ssm:${var.aws_region}:${var.aws_account}:parameter/schoolsmart/${var.env}/*"
      ]
    },
    {
      effect = "Allow"
      actions = [
        "s3:GetObject"
      ]
      resources = [
        "arn:aws:s3:::${var.auth_bucket}/*"
      ]
    },
    {
      effect = "Allow"
      actions = [
        "dynamodb:Query",
        "dynamodb:UpdateItem"
      ]
      resources = [
        "arn:aws:dynamodb:${var.aws_region}:${var.aws_account}:table/*",
        "arn:aws:dynamodb:${var.aws_region}:${var.aws_account}:table/*/index/*"
      ]
    }
  ]
}

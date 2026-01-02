module "webhooks_lambda" {
  source = "../modules/lambda"

  function_name = "xero-webhook"

  iam_policy_statements = [
      {
        effect = "Allow"
        actions = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        resources = [
          "*"
        ]
      },
      {
        effect = "Allow",
        actions = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ],
        resources = [
          "arn:aws:ssm:${var.aws_region}:${var.aws_account}:parameter/schoolsmart/${var.env}/*"
        ]
      },
      {
        effect   = "Allow",
        actions   = [
          "s3:GetObject"
        ],
        resources = [
          "${var.auth_bucket.arn}/*"
        ]
      },
      {
        effect   = "Allow",
        actions   = [
          "dynamodb:Query",
          "dynamodb:UpdateItem"
        ],
        resources = [
          "arn:aws:dynamodb:${var.aws_region}:${var.aws_account}:table/*",
          "arn:aws:dynamodb:${var.aws_region}:${var.aws_account}:table/*/index/*"
        ]
      }
  ]

  env = var.env

  aws_region = var.aws_region
  aws_account_id = var.aws_account

  environment_variables = {
    NODE_ENV         = var.env
    AUTH_BUCKET_NAME = var.auth_bucket.bucket
  }

  s3_bucket = var.lambda_code_bucket.bucket
  s3_key    = "xero-webhook/20251230-123610-3b04bc925b5130022701ecff9be8b46380b95c5d.zip"

  # API Gateway V2 Trigger
  api_gateway_v2_config = {
    api_id     = var.api_gateway_v2_api_id
    route_keys = ["POST /webhooks"]
  }

}

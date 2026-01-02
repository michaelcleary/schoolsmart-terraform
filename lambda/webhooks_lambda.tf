module "webhooks_lambda" {
  source = "../modules/lambda"

  function_name = "xero-webhook"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect   = "Allow",
        Resource = "*"
      },
      {
        Effect   = "Allow",
        Action   = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ],
        Resource = "arn:aws:ssm:${var.aws_region}:${var.aws_account}:parameter/schoolsmart/${var.env}/*"
      },
      {
        Effect   = "Allow",
        Action   = [
          "s3:GetObject"
        ],
        Resource = "${var.auth_bucket.arn}/*"
      },
      {
        Effect   = "Allow",
        Action   = [
          "dynamodb:Query",
          "dynamodb:UpdateItem"
        ],
        "Resource": [
          "arn:aws:dynamodb:${var.aws_region}:${var.aws_account}:table/*",
          "arn:aws:dynamodb:${var.aws_region}:${var.aws_account}:table/*/index/*"
        ]
      }
    ]
  })
}

  env = var.env

  environment_variables = {
    NODE_ENV         = var.env
    AUTH_BUCKET_NAME = var.auth_bucket
  }

  s3_bucket = var.lambda_code_bucket.bucket
  s3_key    = "xero-webhook/20251230-123610-3b04bc925b5130022701ecff9be8b46380b95c5d.zip"

  # API Gateway V2 Trigger
  api_gateway_v2_config = {
    api_id     = var.api_gateway_v2_api_id
    route_keys = ["POST /webhooks"]
  }

  environment {
    variables = {
      NODE_ENV = var.env,
      AUTH_BUCKET_NAME = var.auth_bucket.bucket
    }
  ]
}

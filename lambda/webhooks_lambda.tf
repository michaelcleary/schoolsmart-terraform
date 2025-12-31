resource "aws_iam_role" "webhooks_lambda_execution_role" {
  name = "webhooks_lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "webhooks_lambda_policy" {
  name        = "webhooks_lambda_policy"
  description = "IAM policy for Lambda to interact with other AWS services."

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

resource "aws_iam_role_policy_attachment" "webhooks_lambda_execution_policy_attachment" {
  role       = aws_iam_role.webhooks_lambda_execution_role.name
  policy_arn = aws_iam_policy.webhooks_lambda_policy.arn
}

resource "aws_lambda_function" "webhooks_lambda" {
  function_name = "xero-webhook"
  role          = aws_iam_role.webhooks_lambda_execution_role.arn
  handler       = "index.handler"
  runtime       = "nodejs22.x"

  s3_bucket = var.lambda_code_bucket.bucket
  s3_key    = "xero-webhook/20251230-123610-3b04bc925b5130022701ecff9be8b46380b95c5d.zip"

  timeout = 10
  memory_size = 128

  environment {
    variables = {
      NODE_ENV = var.env,
      AUTH_BUCKET_NAME = var.auth_bucket.bucket
    }
  }
}

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
        Resource = "arn:aws:s3:::${var.auth_bucket}/*"
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

data "archive_file" "dummy_source" {
  type        = "zip"
  source_dir  = "./lambda/dummy"
  output_path = "../lambda/dummy.zip"
}

resource "aws_s3_object" "webhooks_lambda_js" {
  bucket = var.lambda_code_bucket.bucket
  key    = "dummy.zip"
  source = data.archive_file.dummy_source.output_path
  etag   = filemd5(data.archive_file.dummy_source.output_path)
}

resource "aws_lambda_function" "webhooks_lambda" {
  function_name = "xero-webhook"
  role          = aws_iam_role.webhooks_lambda_execution_role.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"

  s3_bucket = var.lambda_code_bucket.bucket
  s3_key    = aws_s3_object.webhooks_lambda_js.key

  timeout = 10
  memory_size = 128

  source_code_hash = data.archive_file.dummy_source.output_base64sha256

  depends_on  = [
    aws_s3_object.webhooks_lambda_js
  ]

  environment {
    variables = {
      NODE_ENV = var.env,
      AUTH_BUCKET_NAME = var.auth_bucket
    }
  }
}

module "invoice_handler_lambda" {
  source = "../modules/lambda"

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

resource "aws_iam_policy" "invoice_handler_lambda_policy" {
  name        = "invoice_handler_lambda_policy"
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
          "dynamodb:BatchGetItem",
          "dynamodb:Query",
          "dynamodb:UpdateItem"
        ],
        "Resource": [
          "arn:aws:dynamodb:${var.aws_region}:${var.aws_account}:table/*",
          "arn:aws:dynamodb:${var.aws_region}:${var.aws_account}:table/*/index/*"
        ]
      },
      {
        Effect   = "Allow",
        Action   = [
          "dynamodb:GetRecords",
          "dynamodb:GetShardIterator",
          "dynamodb:DescribeStream",
          "dynamodb:ListStreams"
        ],
        Resource = var.invoices_table_stream_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "invoice_handler_lambda_execution_policy_attachment" {
  role       = aws_iam_role.invoice_handler_lambda_execution_role.name
  policy_arn = aws_iam_policy.invoice_handler_lambda_policy.arn
}

resource "aws_lambda_function" "invoice_handler_lambda" {
  function_name = "invoice-handler"

  s3_bucket = var.lambda_code_bucket.bucket
  s3_key    = "invoice-handler/20251230-135633-5ebccb6f01cffb9f455e4189a5adc8d24cfe3567.zip"

  env = var.env

  environment {
    variables = {
      NODE_ENV = var.env,
      AUTH_BUCKET_NAME = var.auth_bucket.bucket
    }
  }

  # DynamoDB Stream Trigger
  dynamodb_stream_config = {
    event_source_arn  = var.invoices_table_stream_arn
    starting_position = "LATEST"
    batch_size        = 100
    filter_patterns = [
      jsonencode({
        eventName = ["INSERT", "MODIFY"]
      })
    ]
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
        "dynamodb:BatchGetItem",
        "dynamodb:Query",
        "dynamodb:UpdateItem"
      ]
      resources = [
        "arn:aws:dynamodb:${var.aws_region}:${var.aws_account}:table/*",
        "arn:aws:dynamodb:${var.aws_region}:${var.aws_account}:table/*/index/*"
      ]
    },
    {
      effect = "Allow"
      actions = [
        "dynamodb:GetRecords",
        "dynamodb:GetShardIterator",
        "dynamodb:DescribeStream",
        "dynamodb:ListStreams"
      ]
      resources = [
        var.invoices_table_stream_arn
      ]
    }
  ]
}

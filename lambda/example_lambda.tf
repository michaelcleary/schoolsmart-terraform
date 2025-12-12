resource "aws_iam_role" "example_lambda_execution_role" {
  name = "example_lambda_execution_role"

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

resource "aws_iam_policy" "example_lambda_policy" {
  name        = "example_lambda_policy"
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
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "example_lambda_execution_policy_attachment" {
  role       = aws_iam_role.example_lambda_execution_role.name
  policy_arn = aws_iam_policy.example_lambda_policy.arn
}

data "archive_file" "example_source" {
  type        = "zip"
  source_dir  = "./lambda/dummy"
  output_path = "../lambda/dummy.zip"
}

resource "aws_s3_object" "example_lambda_js" {
  bucket = var.lambda_code_bucket.bucket
  key    = "dummy.zip"
  source = data.archive_file.example_source.output_path
  etag   = filemd5(data.archive_file.example_source.output_path)
}

resource "aws_lambda_function" "example_lambda" {
  function_name = "example-handler"
  role          = aws_iam_role.example_lambda_execution_role.arn
  handler       = "index.handler"
  runtime       = "nodejs22.x"

  s3_bucket = var.lambda_code_bucket.bucket
  s3_key    = aws_s3_object.example_lambda_js.key

  timeout = 10
  memory_size = 128

  source_code_hash = data.archive_file.example_source.output_base64sha256

  depends_on  = [
    aws_s3_object.example_lambda_js
  ]

  environment {
    variables = {
      ENV = var.env
    }
  }
}

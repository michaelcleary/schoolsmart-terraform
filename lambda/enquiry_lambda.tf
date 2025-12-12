resource "aws_iam_role" "enquiry_lambda_execution_role" {
  name = "enquiry_lambda_execution_role"

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

resource "aws_iam_policy" "enquiry_lambda_policy" {
  name        = "enquiry_lambda_policy"
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

resource "aws_iam_role_policy_attachment" "enquiry_lambda_execution_policy_attachment" {
  role       = aws_iam_role.enquiry_lambda_execution_role.name
  policy_arn = aws_iam_policy.enquiry_lambda_policy.arn
}

data "archive_file" "enquiry_source" {
  type        = "zip"
  source_dir  = "./lambda/enquiry"
  output_path = "../lambda/enquiry.zip"
}

resource "aws_s3_object" "enquiry_lambda_js" {
  bucket = var.lambda_code_bucket.bucket
  key    = "enquiry.zip"
  source = data.archive_file.enquiry_source.output_path
  etag   = filemd5(data.archive_file.enquiry_source.output_path)
}

resource "aws_lambda_function" "enquiry_form_lambda" {
  function_name = "form_handler_lambda"
  role          = aws_iam_role.enquiry_lambda_execution_role.arn
  handler       = "index.handler"
  runtime       = "nodejs22.x"

  s3_bucket = var.lambda_code_bucket.bucket
  s3_key    = aws_s3_object.enquiry_lambda_js.key

  timeout = 10
  memory_size = 128

  source_code_hash = data.archive_file.enquiry_source.output_base64sha256

  depends_on  = [
    aws_s3_object.enquiry_lambda_js
  ]

  environment {
    variables = {
      ENV = "production"
    }
  }
}

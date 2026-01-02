resource "aws_iam_role" "auth_refresh_lambda_execution_role" {
  name = "auth_refresh_lambda_execution_role"

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

resource "aws_iam_policy" "auth_refresh_lambda_policy" {
  name        = "auth_refresh_lambda_policy"
  description = "IAM policy for scheduled Lambda to interact with other AWS services."

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
          "s3:GetObject",
          "s3:PutObject"
        ],
        Resource = "${var.auth_bucket.arn}/*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "auth_refresh_lambda_execution_policy_attachment" {
  role       = aws_iam_role.auth_refresh_lambda_execution_role.name
  policy_arn = aws_iam_policy.auth_refresh_lambda_policy.arn
}

resource "aws_lambda_function" "auth_refresh_lambda" {
  function_name = "auth-refresh-handler"
  role          = aws_iam_role.auth_refresh_lambda_execution_role.arn
  handler       = "index.handler"
  runtime       = "nodejs22.x"

  s3_bucket = var.lambda_code_bucket.bucket
  s3_key    = "auth-refresh/20251230-123601-3b04bc925b5130022701ecff9be8b46380b95c5d.zip"

  timeout = 10
  memory_size = 128

  environment {
    variables = {
      NODE_ENV = var.env
      AUTH_BUCKET_NAME = var.auth_bucket.bucket
    }
  }
}

resource "aws_cloudwatch_event_rule" "auth_refresh_lambda_trigger" {
  name                = "scheduled-lambda-trigger"
  description         = "Triggers the scheduled Lambda on the hour and half hour"
  schedule_expression = "cron(0,30 * * * ? *)"
}

resource "aws_cloudwatch_event_target" "auth_refresh_lambda_target" {
  rule      = aws_cloudwatch_event_rule.auth_refresh_lambda_trigger.name
  target_id = "ScheduledLambdaTarget"
  arn       = aws_lambda_function.auth_refresh_lambda.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auth_refresh_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.auth_refresh_lambda_trigger.arn
}
module "invoice_handler_lambda" {
  source = "../modules/lambda"

  function_name = "invoice-handler"

  s3_bucket = var.lambda_code_bucket.bucket
  s3_key    = "invoice-handler/20251213-155810-80f5ff160469467a75e6bed8951f73343dc38f93.zip"

  env = var.env

  environment_variables = {
    NODE_ENV         = var.env
    AUTH_BUCKET_NAME = var.auth_bucket
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

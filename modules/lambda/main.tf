# Local variables for merging default and custom environment variables
locals {
  default_env_vars = {
    ENV = var.env
    NODE_ENV = var.env
  }

  # Merge default environment variables with user-provided ones
  # User-provided variables take precedence
  merged_env_vars = merge(local.default_env_vars, var.environment_variables)
}

# Data source for packaging local source code
data "archive_file" "lambda_source" {
  count       = var.source_dir != null ? 1 : 0
  type        = "zip"
  source_dir  = var.source_dir
  output_path = "${path.module}/.terraform/lambda_packages/${var.function_name}.zip"
}

# IAM Role for Lambda Execution
resource "aws_iam_role" "lambda_execution_role" {
  name = "${var.function_name}_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# CloudWatch Logs Policy (optional, enabled by default)
resource "aws_iam_policy" "cloudwatch_logs_policy" {
  count       = var.attach_cloudwatch_logs_policy ? 1 : 0
  name        = "${var.function_name}_cloudwatch_logs_policy"
  description = "CloudWatch Logs policy for ${var.function_name}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "cloudwatch_logs_attachment" {
  count      = var.attach_cloudwatch_logs_policy ? 1 : 0
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.cloudwatch_logs_policy[0].arn
}

# VPC Execution Policy (if VPC config is provided)
resource "aws_iam_role_policy_attachment" "vpc_execution_role" {
  count      = var.vpc_config != null ? 1 : 0
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Custom IAM Policy with configurable statements
resource "aws_iam_policy" "lambda_custom_policy" {
  count       = length(var.iam_policy_statements) > 0 ? 1 : 0
  name        = "${var.function_name}_custom_policy"
  description = "Custom IAM policy for ${var.function_name}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      for statement in var.iam_policy_statements : {
        Effect   = statement.effect
        Action   = statement.actions
        Resource = statement.resources
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda_custom_policy_attachment" {
  count      = length(var.iam_policy_statements) > 0 ? 1 : 0
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_custom_policy[0].arn
}

# Additional Policy ARN Attachments
resource "aws_iam_role_policy_attachment" "additional_policies" {
  for_each   = toset(var.additional_policy_arns)
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = each.value
}

# Lambda Function
resource "aws_lambda_function" "function" {
  function_name = var.function_name
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = var.handler
  runtime       = var.runtime

  # Code source - either S3 or local
  s3_bucket        = var.s3_bucket
  s3_key           = var.s3_key
  filename         = var.source_dir != null ? data.archive_file.lambda_source[0].output_path : null
  source_code_hash = var.source_code_hash != null ? var.source_code_hash : (var.source_dir != null ? data.archive_file.lambda_source[0].output_base64sha256 : null)

  timeout     = var.timeout
  memory_size = var.memory_size

  reserved_concurrent_executions = var.reserved_concurrent_executions

  # Environment variables
  environment {
    variables = local.merged_env_vars
  }

  # VPC configuration
  dynamic "vpc_config" {
    for_each = var.vpc_config != null ? [var.vpc_config] : []
    content {
      subnet_ids         = var.vpc_config.subnet_ids
      security_group_ids = var.vpc_config.security_group_ids
    }
  }

  # Dead letter queue
  dynamic "dead_letter_config" {
    for_each = var.dead_letter_config != null ? [var.dead_letter_config] : []
    content {
      target_arn = var.dead_letter_config.target_arn
    }
  }

  # Layers
  layers = var.layers

  tags = var.tags

  depends_on = [
    aws_iam_role_policy_attachment.cloudwatch_logs_attachment,
    aws_iam_role_policy_attachment.lambda_custom_policy_attachment,
    aws_iam_role_policy_attachment.vpc_execution_role
  ]
}

# ==================== TRIGGERS ====================

# DynamoDB Stream Trigger
resource "aws_lambda_event_source_mapping" "dynamodb_stream" {
  count             = var.dynamodb_stream_config != null ? 1 : 0
  event_source_arn  = var.dynamodb_stream_config.event_source_arn
  function_name     = aws_lambda_function.function.arn
  starting_position = var.dynamodb_stream_config.starting_position
  batch_size        = var.dynamodb_stream_config.batch_size

  dynamic "filter_criteria" {
    for_each = length(var.dynamodb_stream_config.filter_patterns) > 0 ? [1] : []
    content {
      dynamic "filter" {
        for_each = var.dynamodb_stream_config.filter_patterns
        content {
          pattern = filter.value
        }
      }
    }
  }
}

# SQS Trigger
resource "aws_lambda_event_source_mapping" "sqs" {
  count            = var.sqs_config != null ? 1 : 0
  event_source_arn = var.sqs_config.event_source_arn
  function_name    = aws_lambda_function.function.arn
  batch_size       = var.sqs_config.batch_size
}

# API Gateway V2 (HTTP API) Trigger
resource "aws_lambda_permission" "api_gateway_v2" {
  count         = var.api_gateway_v2_config != null ? 1 : 0
  statement_id  = "AllowAPIGatewayV2Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.aws_region}:${var.aws_account_id}:${var.api_gateway_v2_config.api_id}/*"
}

resource "aws_apigatewayv2_integration" "api_gateway_v2_integration" {
  count            = var.api_gateway_v2_config != null ? 1 : 0
  api_id           = var.api_gateway_v2_config.api_id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.function.invoke_arn
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "api_gateway_v2_route" {
  for_each           = var.api_gateway_v2_config != null ? toset(var.api_gateway_v2_config.route_keys) : toset([])
  api_id             = var.api_gateway_v2_config.api_id
  route_key          = each.value
  target             = "integrations/${aws_apigatewayv2_integration.api_gateway_v2_integration[0].id}"
  authorization_type = var.api_gateway_v2_config.authorization_type
  authorizer_id      = var.api_gateway_v2_config.authorizer_id
}

# EventBridge (CloudWatch Events) Trigger
resource "aws_cloudwatch_event_rule" "eventbridge_rule" {
  count               = var.eventbridge_config != null ? 1 : 0
  name                = var.eventbridge_config.rule_name
  description         = var.eventbridge_config.description
  schedule_expression = var.eventbridge_config.schedule_expression
  event_pattern       = var.eventbridge_config.event_pattern

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "eventbridge_target" {
  count     = var.eventbridge_config != null ? 1 : 0
  rule      = aws_cloudwatch_event_rule.eventbridge_rule[0].name
  target_id = "lambda"
  arn       = aws_lambda_function.function.arn
}

resource "aws_lambda_permission" "eventbridge" {
  count         = var.eventbridge_config != null ? 1 : 0
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.function.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.eventbridge_rule[0].arn
}

# S3 Trigger
resource "aws_lambda_permission" "s3" {
  count         = var.s3_trigger_config != null ? 1 : 0
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.function.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${var.s3_trigger_config.bucket_id}"
}

resource "aws_s3_bucket_notification" "s3_notification" {
  count  = var.s3_trigger_config != null ? 1 : 0
  bucket = var.s3_trigger_config.bucket_id

  lambda_function {
    lambda_function_arn = aws_lambda_function.function.arn
    events              = var.s3_trigger_config.events
    filter_prefix       = var.s3_trigger_config.filter_prefix
    filter_suffix       = var.s3_trigger_config.filter_suffix
  }

  depends_on = [aws_lambda_permission.s3]
}

# SNS Trigger
resource "aws_sns_topic_subscription" "sns_subscription" {
  count     = var.sns_config != null ? 1 : 0
  topic_arn = var.sns_config.topic_arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.function.arn
}

resource "aws_lambda_permission" "sns" {
  count         = var.sns_config != null ? 1 : 0
  statement_id  = "AllowSNSInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.function.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = var.sns_config.topic_arn
}

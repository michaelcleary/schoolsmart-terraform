# Lambda Module

A comprehensive Terraform module for creating AWS Lambda functions with support for multiple trigger types and flexible IAM configurations.

## Features

- **Multiple Trigger Types**: DynamoDB Streams, SQS, API Gateway, EventBridge, S3, SNS
- **Flexible IAM Permissions**: Configure custom policy statements via module parameters
- **Code Deployment Options**: Support for both S3-based and local source code deployment
- **Optional Features**: VPC configuration, layers, reserved concurrency, dead letter queues
- **CloudWatch Logs**: Automatic CloudWatch Logs policy (can be disabled)

## Usage Examples

### Basic Lambda Function with S3 Code

```hcl
module "simple_lambda" {
  source = "./modules/lambda"

  function_name = "my-simple-function"
  handler       = "index.handler"
  runtime       = "nodejs22.x"

  s3_bucket = "my-lambda-code-bucket"
  s3_key    = "my-function/deployment.zip"

  timeout     = 30
  memory_size = 256

  environment_variables = {
    NODE_ENV = "production"
    API_KEY  = "secret-key"
  }
}
```

### Lambda with Local Source Code

```hcl
module "local_lambda" {
  source = "./modules/lambda"

  function_name = "my-local-function"
  handler       = "index.handler"
  runtime       = "nodejs22.x"

  source_dir = "./lambda/my-function"

  environment_variables = {
    ENV = "production"
  }
}
```

### Lambda with DynamoDB Stream Trigger

```hcl
module "dynamodb_lambda" {
  source = "./modules/lambda"

  function_name = "invoice-handler"
  handler       = "index.handler"
  runtime       = "nodejs22.x"

  s3_bucket = var.lambda_code_bucket.bucket
  s3_key    = "invoice-handler/deployment.zip"

  # DynamoDB Stream Trigger
  dynamodb_stream_config = {
    event_source_arn  = aws_dynamodb_table.invoices.stream_arn
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
        "dynamodb:GetRecords",
        "dynamodb:GetShardIterator",
        "dynamodb:DescribeStream",
        "dynamodb:ListStreams"
      ]
      resources = [aws_dynamodb_table.invoices.stream_arn]
    },
    {
      effect = "Allow"
      actions = [
        "dynamodb:Query",
        "dynamodb:UpdateItem"
      ]
      resources = [
        "arn:aws:dynamodb:${var.aws_region}:${var.aws_account}:table/*"
      ]
    }
  ]

  environment_variables = {
    NODE_ENV = var.env
  }
}
```

### Lambda with SQS Trigger

```hcl
module "sqs_lambda" {
  source = "./modules/lambda"

  function_name = "queue-processor"
  handler       = "index.handler"
  runtime       = "python3.12"

  s3_bucket = var.lambda_code_bucket.bucket
  s3_key    = "queue-processor/deployment.zip"

  # SQS Trigger
  sqs_config = {
    event_source_arn = aws_sqs_queue.my_queue.arn
    batch_size       = 10
  }

  # IAM Permissions
  iam_policy_statements = [
    {
      effect = "Allow"
      actions = [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes"
      ]
      resources = [aws_sqs_queue.my_queue.arn]
    }
  ]
}
```

### Lambda with API Gateway V2 (HTTP API) Trigger

```hcl
module "api_lambda" {
  source = "./modules/lambda"

  function_name = "api-handler"
  s3_bucket     = var.lambda_code_bucket.bucket
  s3_key        = "api-handler/deployment.zip"

  env            = var.env
  aws_region     = var.aws_region
  aws_account_id = var.aws_account_id

  # API Gateway V2 Trigger - Single route
  api_gateway_v2_config = {
    api_id     = aws_apigatewayv2_api.admin_api.id
    route_keys = ["POST /webhook"]
  }

  environment_variables = {
    API_VERSION = "v1"
  }
}
```

### Lambda with Multiple HTTP Methods

```hcl
module "multi_method_lambda" {
  source = "./modules/lambda"

  function_name = "user-handler"
  s3_bucket     = var.lambda_code_bucket.bucket
  s3_key        = "user-handler/deployment.zip"

  env            = var.env
  aws_region     = var.aws_region
  aws_account_id = var.aws_account_id

  # API Gateway V2 Trigger - Multiple routes (GET and POST)
  api_gateway_v2_config = {
    api_id     = aws_apigatewayv2_api.admin_api.id
    route_keys = ["GET /users", "POST /users", "PUT /users/{id}", "DELETE /users/{id}"]
  }

  iam_policy_statements = [
    {
      effect = "Allow"
      actions = [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem"
      ]
      resources = ["arn:aws:dynamodb:${var.aws_region}:${var.aws_account_id}:table/users"]
    }
  ]
}
```

### Lambda with EventBridge Schedule

```hcl
module "scheduled_lambda" {
  source = "./modules/lambda"

  function_name = "daily-report"
  handler       = "index.handler"
  runtime       = "nodejs22.x"

  s3_bucket = var.lambda_code_bucket.bucket
  s3_key    = "daily-report/deployment.zip"

  # EventBridge Schedule (runs daily at 9 AM UTC)
  eventbridge_config = {
    rule_name           = "daily-report-schedule"
    schedule_expression = "cron(0 9 * * ? *)"
    description         = "Trigger daily report generation"
  }
}
```

### Lambda with S3 Trigger

```hcl
module "s3_lambda" {
  source = "./modules/lambda"

  function_name = "image-processor"
  handler       = "index.handler"
  runtime       = "python3.12"

  s3_bucket = var.lambda_code_bucket.bucket
  s3_key    = "image-processor/deployment.zip"

  # S3 Trigger
  s3_trigger_config = {
    bucket_id     = aws_s3_bucket.uploads.id
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "images/"
    filter_suffix = ".jpg"
  }

  # IAM Permissions
  iam_policy_statements = [
    {
      effect = "Allow"
      actions = [
        "s3:GetObject"
      ]
      resources = ["${aws_s3_bucket.uploads.arn}/*"]
    }
  ]
}
```

### Lambda with SNS Trigger

```hcl
module "sns_lambda" {
  source = "./modules/lambda"

  function_name = "notification-handler"
  handler       = "index.handler"
  runtime       = "nodejs22.x"

  s3_bucket = var.lambda_code_bucket.bucket
  s3_key    = "notification-handler/deployment.zip"

  # SNS Trigger
  sns_config = {
    topic_arn = aws_sns_topic.notifications.arn
  }
}
```

### Lambda with VPC Configuration

```hcl
module "vpc_lambda" {
  source = "./modules/lambda"

  function_name = "database-query"
  handler       = "index.handler"
  runtime       = "nodejs22.x"

  s3_bucket = var.lambda_code_bucket.bucket
  s3_key    = "database-query/deployment.zip"

  # VPC Configuration
  vpc_config = {
    subnet_ids         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  # IAM Permissions for RDS
  iam_policy_statements = [
    {
      effect = "Allow"
      actions = [
        "rds:DescribeDBInstances",
        "rds-db:connect"
      ]
      resources = ["*"]
    }
  ]
}
```

### Lambda with Custom Policy ARNs and Complex IAM

```hcl
module "complex_lambda" {
  source = "./modules/lambda"

  function_name = "complex-processor"
  handler       = "index.handler"
  runtime       = "nodejs22.x"

  s3_bucket = var.lambda_code_bucket.bucket
  s3_key    = "complex-processor/deployment.zip"

  timeout     = 60
  memory_size = 512

  # Custom IAM Policy Statements
  iam_policy_statements = [
    {
      effect = "Allow"
      actions = [
        "ssm:GetParameter",
        "ssm:GetParameters",
        "ssm:GetParametersByPath"
      ]
      resources = [
        "arn:aws:ssm:${var.aws_region}:${var.aws_account}:parameter/app/${var.env}/*"
      ]
    },
    {
      effect = "Allow"
      actions = [
        "s3:GetObject",
        "s3:PutObject"
      ]
      resources = [
        "arn:aws:s3:::my-bucket/*"
      ]
    },
    {
      effect = "Allow"
      actions = [
        "dynamodb:Query",
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem"
      ]
      resources = [
        "arn:aws:dynamodb:${var.aws_region}:${var.aws_account}:table/my-table",
        "arn:aws:dynamodb:${var.aws_region}:${var.aws_account}:table/my-table/index/*"
      ]
    }
  ]

  # Additional managed policies
  additional_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSESFullAccess"
  ]

  # Lambda Layers
  layers = [
    "arn:aws:lambda:us-east-1:123456789012:layer:my-layer:1"
  ]

  # Dead Letter Queue
  dead_letter_config = {
    target_arn = aws_sqs_queue.dlq.arn
  }

  # Reserved Concurrency
  reserved_concurrent_executions = 10

  environment_variables = {
    NODE_ENV        = var.env
    TABLE_NAME      = "my-table"
    BUCKET_NAME     = "my-bucket"
  }

  tags = {
    Environment = var.env
    Application = "my-app"
  }
}
```

## Variables

### Required Variables

| Name | Description | Type |
|------|-------------|------|
| `function_name` | Name of the Lambda function | `string` |
| `handler` | Lambda function handler | `string` |
| `runtime` | Lambda runtime | `string` |

### Code Source Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `s3_bucket` | S3 bucket containing the Lambda code | `string` | `null` |
| `s3_key` | S3 key for the Lambda code | `string` | `null` |
| `source_dir` | Local directory containing Lambda source code | `string` | `null` |
| `source_code_hash` | Base64-encoded SHA256 hash of the package file | `string` | `null` |

### IAM Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `iam_policy_statements` | List of IAM policy statements | `list(object)` | `[]` |
| `attach_cloudwatch_logs_policy` | Whether to attach CloudWatch Logs policy | `bool` | `true` |
| `additional_policy_arns` | List of additional IAM policy ARNs | `list(string)` | `[]` |

### Function Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `timeout` | Lambda function timeout in seconds | `number` | `10` |
| `memory_size` | Lambda function memory size in MB | `number` | `128` |
| `environment_variables` | Environment variables | `map(string)` | `{}` |
| `layers` | List of Lambda layer ARNs | `list(string)` | `[]` |
| `reserved_concurrent_executions` | Reserved concurrent executions | `number` | `-1` |

### Trigger Configuration Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `dynamodb_stream_config` | DynamoDB Stream trigger configuration | `object` | `null` |
| `sqs_config` | SQS trigger configuration | `object` | `null` |
| `api_gateway_config` | API Gateway trigger configuration | `object` | `null` |
| `eventbridge_config` | EventBridge trigger configuration | `object` | `null` |
| `s3_trigger_config` | S3 trigger configuration | `object` | `null` |
| `sns_config` | SNS trigger configuration | `object` | `null` |

### Optional Features

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `vpc_config` | VPC configuration | `object` | `null` |
| `dead_letter_config` | Dead letter queue configuration | `object` | `null` |
| `tags` | Tags to apply to resources | `map(string)` | `{}` |

## Outputs

| Name | Description |
|------|-------------|
| `function_arn` | ARN of the Lambda function |
| `function_name` | Name of the Lambda function |
| `invoke_arn` | Invoke ARN of the Lambda function |
| `qualified_arn` | Qualified ARN of the Lambda function |
| `role_arn` | ARN of the IAM role |
| `role_name` | Name of the IAM role |
| `function_version` | Latest published version |
| `source_code_hash` | Base64-encoded SHA256 hash |
| `api_gateway_resource_id` | ID of the API Gateway resource (if created) |
| `eventbridge_rule_arn` | ARN of the EventBridge rule (if created) |

## Notes

- Either `s3_bucket`/`s3_key` OR `source_dir` must be provided for code deployment
- Only one trigger type should be configured per Lambda function
- CloudWatch Logs policy is attached by default, set `attach_cloudwatch_logs_policy = false` to disable
- VPC configuration automatically attaches the `AWSLambdaVPCAccessExecutionRole` managed policy

# Required Variables
variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "handler" {
  description = "Lambda function handler (e.g., index.handler)"
  type        = string
  default     = "index.handler"
}

variable "runtime" {
  description = "Lambda runtime (e.g., nodejs22.x, python3.12)"
  type        = string
  default     = "nodejs22.x"
}

# Code Source Variables
variable "s3_bucket" {
  description = "S3 bucket containing the Lambda code"
  type        = string
  default     = null
}

variable "s3_key" {
  description = "S3 key for the Lambda code"
  type        = string
  default     = null
}

variable "source_dir" {
  description = "Local directory containing Lambda source code (alternative to S3)"
  type        = string
  default     = null
}

variable "source_code_hash" {
  description = "Base64-encoded SHA256 hash of the package file"
  type        = string
  default     = null
}

# IAM Variables
variable "iam_policy_statements" {
  description = "List of IAM policy statements for the Lambda function"
  type = list(object({
    effect    = string
    actions   = list(string)
    resources = list(string)
  }))
  default = []
}

variable "attach_cloudwatch_logs_policy" {
  description = "Whether to attach CloudWatch Logs policy"
  type        = bool
  default     = true
}

variable "additional_policy_arns" {
  description = "List of additional IAM policy ARNs to attach to the Lambda role"
  type        = list(string)
  default     = []
}

# Function Configuration
variable "timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 10
}

variable "memory_size" {
  description = "Lambda function memory size in MB"
  type        = number
  default     = 128
}

variable "environment_variables" {
  description = "Environment variables for the Lambda function"
  type        = map(string)
  default     = {}
}

variable "layers" {
  description = "List of Lambda layer ARNs"
  type        = list(string)
  default     = []
}

variable "reserved_concurrent_executions" {
  description = "Reserved concurrent executions for the Lambda function"
  type        = number
  default     = -1
}

# VPC Configuration
variable "vpc_config" {
  description = "VPC configuration for the Lambda function"
  type = object({
    subnet_ids         = list(string)
    security_group_ids = list(string)
  })
  default = null
}

# Dead Letter Queue
variable "dead_letter_config" {
  description = "Dead letter queue configuration"
  type = object({
    target_arn = string
  })
  default = null
}

# Trigger Configuration - DynamoDB Streams
variable "dynamodb_stream_config" {
  description = "DynamoDB Stream trigger configuration"
  type = object({
    event_source_arn  = string
    starting_position = string
    batch_size        = optional(number, 100)
    filter_patterns   = optional(list(string), [])
  })
  default = null
}

# Trigger Configuration - SQS
variable "sqs_config" {
  description = "SQS trigger configuration"
  type = object({
    event_source_arn = string
    batch_size       = optional(number, 10)
  })
  default = null
}

# Trigger Configuration - API Gateway V2 (HTTP API)
variable "api_gateway_v2_config" {
  description = "API Gateway V2 (HTTP API) trigger configuration. Supports multiple route keys (HTTP methods) per lambda."
  type = object({
    api_id      = string
    route_keys  = list(string)  # List of route keys like ["POST /submit", "GET /submit"]
    authorization_type = optional(string, "NONE")
    authorizer_id      = optional(string, null)
  })
  default = null
}

# Trigger Configuration - EventBridge
variable "eventbridge_config" {
  description = "EventBridge (CloudWatch Events) trigger configuration"
  type = object({
    rule_name           = string
    schedule_expression = optional(string, null)
    event_pattern       = optional(string, null)
    description         = optional(string, "")
  })
  default = null
}

# Trigger Configuration - S3
variable "s3_trigger_config" {
  description = "S3 trigger configuration"
  type = object({
    bucket_id = string
    events    = list(string)
    filter_prefix = optional(string, "")
    filter_suffix = optional(string, "")
  })
  default = null
}

# Trigger Configuration - SNS
variable "sns_config" {
  description = "SNS trigger configuration"
  type = object({
    topic_arn = string
  })
  default = null
}

# Tags
variable "tags" {
  description = "Tags to apply to Lambda resources"
  type        = map(string)
  default     = {}
}

# Context Variables (for common patterns)
variable "env" {
  description = "Environment name (used in default ENV environment variable)"
  type        = string
  default     = "production"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = ""
}

variable "aws_account_id" {
  description = "AWS account ID"
  type        = string
  default     = ""
}

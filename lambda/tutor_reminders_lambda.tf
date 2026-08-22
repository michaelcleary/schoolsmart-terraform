module "tutor_reminders_lambda" {
  source = "../modules/lambda"

  function_name = "tutor-reminders"

  s3_bucket = var.lambda_code_bucket.bucket
  s3_key    = "${var.release_tag}/tutor-reminders.zip"

  env = var.env

  aws_region     = var.aws_region
  aws_account_id = var.aws_account

  # Add EMAIL_OVERRIDE if provided
  environment_variables = var.email_override != null ? {
    EMAIL_OVERRIDE = var.email_override
    SHARED_ACCOUNT = var.shared_services_account_id
  } : {}

  # API Gateway V2 Trigger
  api_gateway_v2_config = {
    api_id     = var.api_gateway_v2_api_id
    route_keys = ["GET /tutor-reminders", "POST /tutor-reminders"]
  }

  # IAM Permissions
  iam_policy_statements = [
    {
      effect = "Allow"
      actions = [
        "dynamodb:BatchGetItem",
        "dynamodb:Query",
        "dynamodb:Scan",
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
        "ses:SendEmail",
        "ses:SendRawEmail"
      ]
      resources = ["*"]
    },
    {
      effect = "Allow",
      actions = ["sts:AssumeRole"],
      resources = [
        "arn:aws:iam::${var.shared_services_account_id}:role/CrossAccountSESSendRole"
      ]
    }
  ]
}

module "cognito_pretokengen_lambda" {
  source = "../modules/lambda"

  function_name = "${var.env}-cognito-pretokengen"

  # Needs AdminAddUserToGroup to perform lazy group migration for users who
  # were migrated from the legacy DynamoDB users table.
  # The ARN is constructed from known components to avoid a circular dependency
  # between the User Pool (which references this Lambda) and this IAM policy
  # (which would reference the User Pool).
  iam_policy_statements = [
    {
      effect    = "Allow"
      actions   = ["cognito-idp:AdminAddUserToGroup"]
      resources = ["arn:aws:cognito-idp:${var.aws_region}:${var.aws_account}:userpool/*"]
    }
  ]

  env            = var.env
  aws_region     = var.aws_region
  aws_account_id = var.aws_account

  # Zip deployed to S3 by the schoolsmart-admin CI/CD pipeline.
  # Update s3_key when a new version is released.
  s3_bucket = var.lambda_code_bucket.bucket
  s3_key    = "cognito-pretokengen/20260504-194138-43e977a5b037ac5821213bd86ae0c3997252e0ec.zip"

  timeout     = 5
  memory_size = 128
}

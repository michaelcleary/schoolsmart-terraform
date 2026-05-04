module "cognito_migration_lambda" {
  source = "../modules/lambda"

  function_name = "${var.env}-cognito-migration"

  iam_policy_statements = [
    {
      effect    = "Allow"
      actions   = ["dynamodb:GetItem"]
      resources = ["arn:aws:dynamodb:${var.aws_region}:${var.aws_account}:table/${var.env}-schoolsmart-admin-users"]
    }
  ]

  env            = var.env
  aws_region     = var.aws_region
  aws_account_id = var.aws_account

  environment_variables = {
    USERS_TABLE = "${var.env}-schoolsmart-admin-users"
  }

  # Zip deployed to S3 by the schoolsmart-admin CI/CD pipeline.
  # Update s3_key when a new version is released.
  s3_bucket = var.lambda_code_bucket.bucket
  s3_key    = "cognito-migration/20260504-194144-43e977a5b037ac5821213bd86ae0c3997252e0ec.zip"

  timeout     = 10
  memory_size = 128
}

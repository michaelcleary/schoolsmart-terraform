# ---------------------------------------------------------------------------
# Cognito User Pool
# ---------------------------------------------------------------------------
# The User Pool is the identity store for the Next.js application.
# The Angular SPA continues to use the legacy Passport.js / JWT path on the
# App Runner service; Cognito is purely additive during the Angular transition.
# ---------------------------------------------------------------------------

# ---- Lambda source packaging ----

# Install npm dependencies for the migration Lambda before archiving.
# Requires npm to be available on the machine running terraform apply.
resource "null_resource" "cognito_migration_npm_install" {
  triggers = {
    package_json = filesha256("${path.module}/lambda/cognito-migration/package.json")
    index_js     = filesha256("${path.module}/lambda/cognito-migration/index.js")
  }

  provisioner "local-exec" {
    command = "npm install --production --prefix ${path.module}/lambda/cognito-migration"
  }
}

data "archive_file" "cognito_migration_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/cognito-migration"
  output_path = "${path.module}/.terraform/lambda_packages/cognito-migration.zip"

  depends_on = [null_resource.cognito_migration_npm_install]
}

data "archive_file" "cognito_pretokengen_zip" {
  type = "zip"
  source {
    content  = file("${path.module}/lambda/cognito-pretokengen/index.js")
    filename = "index.js"
  }
  output_path = "${path.module}/.terraform/lambda_packages/cognito-pretokengen.zip"
}

# ---- IAM: Migration Lambda ----

resource "aws_iam_role" "cognito_migration_lambda_role" {
  name = "${var.env}-cognito-migration-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "cognito_migration_lambda_policy" {
  name        = "${var.env}-cognito-migration-lambda-policy"
  description = "Allows migration Lambda to read legacy users table and write CloudWatch logs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["dynamodb:GetItem"]
        Resource = "arn:aws:dynamodb:${var.aws_region}:${var.aws_account}:table/${var.env}-schoolsmart-admin-users"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cognito_migration_lambda_policy_attachment" {
  role       = aws_iam_role.cognito_migration_lambda_role.name
  policy_arn = aws_iam_policy.cognito_migration_lambda_policy.arn
}

# ---- Lambda: Migration ----

resource "aws_lambda_function" "cognito_migration" {
  function_name    = "${var.env}-cognito-migration"
  role             = aws_iam_role.cognito_migration_lambda_role.arn
  handler          = "index.handler"
  runtime          = "nodejs22.x"
  filename         = data.archive_file.cognito_migration_zip.output_path
  source_code_hash = data.archive_file.cognito_migration_zip.output_base64sha256
  timeout          = 10
  memory_size      = 128

  environment {
    variables = {
      NODE_ENV    = var.env
      USERS_TABLE = "${var.env}-schoolsmart-admin-users"
    }
  }

  tags = {
    Name        = "CognitoMigrationLambda"
    Environment = var.env
  }
}

resource "aws_lambda_permission" "cognito_migration_invoke" {
  statement_id  = "AllowCognitoInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cognito_migration.function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = aws_cognito_user_pool.main.arn
}

# ---- IAM: Pre-Token Generation Lambda ----

resource "aws_iam_role" "cognito_pretokengen_lambda_role" {
  name = "${var.env}-cognito-pretokengen-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "cognito_pretokengen_lambda_policy" {
  name        = "${var.env}-cognito-pretokengen-lambda-policy"
  description = "Allows pre-token generation Lambda to write CloudWatch logs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
      ]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cognito_pretokengen_lambda_policy_attachment" {
  role       = aws_iam_role.cognito_pretokengen_lambda_role.name
  policy_arn = aws_iam_policy.cognito_pretokengen_lambda_policy.arn
}

# ---- Lambda: Pre-Token Generation ----

resource "aws_lambda_function" "cognito_pretokengen" {
  function_name    = "${var.env}-cognito-pretokengen"
  role             = aws_iam_role.cognito_pretokengen_lambda_role.arn
  handler          = "index.handler"
  runtime          = "nodejs22.x"
  filename         = data.archive_file.cognito_pretokengen_zip.output_path
  source_code_hash = data.archive_file.cognito_pretokengen_zip.output_base64sha256
  timeout          = 5
  memory_size      = 128

  environment {
    variables = {
      NODE_ENV = var.env
    }
  }

  tags = {
    Name        = "CognitoPreTokenGenLambda"
    Environment = var.env
  }
}

resource "aws_lambda_permission" "cognito_pretokengen_invoke" {
  statement_id  = "AllowCognitoInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cognito_pretokengen.function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = aws_cognito_user_pool.main.arn
}

# ---- Cognito User Pool ----

resource "aws_cognito_user_pool" "main" {
  name = "${var.env}-schoolsmart"

  username_configuration {
    case_sensitive = false
  }

  # Primary identifier is username; email can also be used as sign-in alias
  # (supports forgot-password flow by email)
  alias_attributes         = ["email"]
  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length                   = 8
    require_lowercase                = true
    require_uppercase                = true
    require_numbers                  = true
    require_symbols                  = true
    temporary_password_validity_days = 7
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  # Email: Cognito managed for now (50 emails/day limit).
  # TODO: For production configure SES in this account and set:
  #   email_configuration { email_sending_account = "DEVELOPER"; source_arn = <ses_identity_arn> }
  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  # Custom attributes used by the migration Lambda and Pre-Token Gen Lambda
  schema {
    name                     = "contactId"
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    string_attribute_constraints {
      min_length = "0"
      max_length = "256"
    }
  }

  schema {
    name                     = "role"
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    string_attribute_constraints {
      min_length = "0"
      max_length = "64"
    }
  }

  lambda_config {
    user_migration = aws_lambda_function.cognito_migration.arn

    pre_token_generation_config {
      lambda_arn     = aws_lambda_function.cognito_pretokengen.arn
      lambda_version = "V2_0"
    }
  }

  tags = {
    Name        = "SchoolSmartUserPool"
    Environment = var.env
  }
}

# ---- App Client (Next.js) ----

resource "aws_cognito_user_pool_client" "nextjs" {
  name         = "nextjs-client"
  user_pool_id = aws_cognito_user_pool.main.id

  # No client secret: calls are made server-side from Next.js API routes
  # (env vars are not exposed to the browser — no NEXT_PUBLIC_ prefix)
  generate_secret = false

  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
  ]

  access_token_validity  = 60 # minutes
  id_token_validity      = 60 # minutes
  refresh_token_validity = 30 # days

  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }

  prevent_user_existence_errors = "ENABLED"
}

# ---- User Pool Domain ----
# Required for the token endpoint even though the Hosted UI is not used.

resource "aws_cognito_user_pool_domain" "main" {
  domain       = "${var.env}-schoolsmart-admin"
  user_pool_id = aws_cognito_user_pool.main.id
}

# ---- User Groups (role-based access) ----

resource "aws_cognito_user_group" "admin" {
  name         = "admin"
  user_pool_id = aws_cognito_user_pool.main.id
  description  = "School administrators"
}

resource "aws_cognito_user_group" "partner" {
  name         = "partner"
  user_pool_id = aws_cognito_user_pool.main.id
  description  = "Partner organisations"
}

resource "aws_cognito_user_group" "tutor" {
  name         = "tutor"
  user_pool_id = aws_cognito_user_pool.main.id
  description  = "Tutors"
}

# ---- IAM: Allow App Runner to manage Cognito users ----
# Needed for AdminCreateUser (tutor onboarding) and AdminAddUserToGroup.

resource "aws_iam_policy" "app_runner_cognito_policy" {
  name        = "${var.env}-apprunner-CognitoUserManagement"
  description = "Allow App Runner to manage Cognito users (create, group assignment)"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "cognito-idp:AdminGetUser",
        "cognito-idp:AdminCreateUser",
        "cognito-idp:AdminAddUserToGroup",
        "cognito-idp:AdminSetUserPassword",
      ]
      Resource = aws_cognito_user_pool.main.arn
    }]
  })
}

resource "aws_iam_role_policy_attachment" "app_runner_cognito_access" {
  role       = aws_iam_role.app_runner_instance_role.name
  policy_arn = aws_iam_policy.app_runner_cognito_policy.arn
}

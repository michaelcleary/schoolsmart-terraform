# ---------------------------------------------------------------------------
# Cognito User Pool
# ---------------------------------------------------------------------------
# The User Pool is the identity store for the Next.js application.
# The Angular SPA continues to use the legacy Passport.js / JWT path on the
# App Runner service; Cognito is purely additive during the Angular transition.
#
# Lambda functions (user migration, pre-token generation) are defined in the
# lambda/ module following the same pattern as all other Lambda functions.
# Source code and S3 deployment are managed by the schoolsmart-admin CI/CD.
# ---------------------------------------------------------------------------

# ---- State migration ----
# Lambda functions were originally defined as standalone root resources.
# moved blocks rename them in state so they are not destroyed and recreated.

moved {
  from = aws_lambda_function.cognito_migration
  to   = module.lambda.module.cognito_migration_lambda.aws_lambda_function.function
}

moved {
  from = aws_lambda_function.cognito_pretokengen
  to   = module.lambda.module.cognito_pretokengen_lambda.aws_lambda_function.function
}

# ---- Lambda permissions (Cognito → Lambda) ----
# Kept here rather than in the lambda/ module because they need to reference
# the Cognito User Pool ARN, which is defined in this file.

resource "aws_lambda_permission" "cognito_migration_invoke" {
  statement_id  = "AllowCognitoInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda.cognito_migration_function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = aws_cognito_user_pool.main.arn
}

resource "aws_lambda_permission" "cognito_pretokengen_invoke" {
  statement_id  = "AllowCognitoInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda.cognito_pretokengen_function_name
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

  # Custom attributes used by the migration Lambda and pre-token generation Lambda
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
    user_migration = module.lambda.cognito_migration_function_arn

    pre_token_generation_config {
      lambda_arn     = module.lambda.cognito_pretokengen_function_arn
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

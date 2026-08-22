# OpenNext server function for the Next.js admin app (schoolsmart-terraform-dl3).
# Replaces Amplify WEB_COMPUTE hosting (modules/amplify, amplify.tf) with the same
# release_tag/tfvars-driven deploy shape used by every other lambda: schoolsmart-admin's
# CI builds apps/next with OpenNext and uploads the server bundle to
# s3://<lambda_code_bucket>/<release_tag>/nextjs-server.zip.
#
# Fronted by a catch-all route on the shared admin_api HTTP API — see api-gateway.tf.
# More specific routes (/auth/*, the App Runner /admin/* prefix) win over the catch-all,
# so this only receives what isn't already claimed by those.
#
# Reuses the same Cognito client + session secret as the (still-live) Amplify app so
# sessions issued by either backend stay interchangeable during the dl3/yd1 transition.
module "nextjs_server_lambda" {
  source = "../modules/lambda"

  function_name = "${var.env}-nextjs-server"
  handler       = "index.handler"
  runtime       = "nodejs20.x"

  env            = var.env
  aws_region     = var.aws_region
  aws_account_id = var.aws_account

  environment_variables = {
    API_BASE_URL         = "https://${var.api_domain_name}"
    SESSION_SECRET       = var.nextjs_session_secret
    COGNITO_USER_POOL_ID = var.nextjs_cognito_user_pool_id
    COGNITO_CLIENT_ID    = var.nextjs_cognito_client_id
    COGNITO_REGION       = var.aws_region
  }

  # Zip deployed to S3 by the schoolsmart-admin CI/CD pipeline.
  # Update s3_key when a new version is released.
  s3_bucket = var.lambda_code_bucket.bucket
  s3_key    = "${var.release_tag}/nextjs-server.zip"

  # OpenNext server functions run heavier than the other lambdas in this stack
  # (Next.js runtime + route handlers) — start generous, tune once real traffic exists.
  timeout     = 30
  memory_size = 1024

  api_gateway_v2_config = {
    api_id     = var.api_gateway_v2_api_id
    route_keys = ["ANY /", "ANY /{proxy+}"]
  }
}

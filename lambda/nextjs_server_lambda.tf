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
#
# Gated behind enable_nextjs_lambda: aws_lambda_function creation fails if s3_key doesn't
# exist yet in lambda_code_bucket, which would otherwise fail every apply to this
# workspace (terraform apply is all-or-nothing) until schoolsmart-admin's OpenNext build
# is actually uploading nextjs-server.zip for the release_tag in <env>.tfvars.
module "nextjs_server_lambda" {
  count  = var.enable_nextjs_lambda ? 1 : 0
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

  # TRANSITIONAL: kept alongside function_url_config below purely to avoid a Terraform
  # dependency cycle (nextjs-site.tf's CloudFront distribution referencing
  # module.lambda's new function_url_domain output while these same-module resources are
  # being destroyed, in one apply, cycles). Step 1 of 3: add the Function URL without
  # removing this yet. Step 2: repoint nextjs-site.tf at the Function URL (this still
  # exists so nothing destroys). Step 3: remove this block entirely (pure destroy, nothing
  # references it any more). See nextjs-server-lambda's function_url_config comment for why
  # the Function URL replaces this for actual traffic.
  api_gateway_v2_config = {
    api_id     = var.api_gateway_v2_api_id
    route_keys = ["ANY /", "ANY /{proxy+}"]
    payload_format_version = "2.0"
  }

  # Invoked directly by CloudFront via a Function URL, not the shared admin_api HTTP API.
  # OpenNext's SSR handler is built with awslambda.streamifyResponse (Lambda response
  # streaming) — API Gateway (REST or HTTP API) always uses the standard buffered Invoke
  # API and cannot invoke a streaming handler at all, producing a generic 500 at the API
  # Gateway layer even though the Lambda itself runs fine. (An earlier attempt routed this
  # through admin_api with payload_format_version = "2.0", which fixed the 2.0-vs-1.0 event
  # shape mismatch but not this deeper incompatibility — replaced by this Function URL.)
  function_url_config = {
    invoke_mode                 = "RESPONSE_STREAM"
    authorized_source_account   = var.aws_account
    authorized_distribution_arn = var.nextjs_cloudfront_distribution_arn
  }
}

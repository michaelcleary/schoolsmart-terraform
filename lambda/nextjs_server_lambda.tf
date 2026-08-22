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
    # Checked against the X-Origin-Verify header CloudFront sends on every request (see
    # nextjs-site.tf's default_origin_custom_headers) — the Function URL itself has no
    # IAM-based access control (authorization_type = NONE, see function_url_config below),
    # so schoolsmart-admin's handler must reject any request without a matching header.
    ORIGIN_VERIFY_SECRET = var.nextjs_origin_verify_secret
  }

  # Zip deployed to S3 by the schoolsmart-admin CI/CD pipeline.
  # Update s3_key when a new version is released.
  s3_bucket = var.lambda_code_bucket.bucket
  s3_key    = "${var.release_tag}/nextjs-server.zip"

  # OpenNext server functions run heavier than the other lambdas in this stack
  # (Next.js runtime + route handlers) — start generous, tune once real traffic exists.
  timeout     = 30
  memory_size = 1024

  # Invoked directly by CloudFront via a Function URL, not the shared admin_api HTTP API.
  # OpenNext's SSR handler is built with awslambda.streamifyResponse (Lambda response
  # streaming) — API Gateway (REST or HTTP API) always uses the standard buffered Invoke
  # API and cannot invoke a streaming handler at all, producing a generic 500 at the API
  # Gateway layer even though the Lambda itself runs fine.
  #
  # authorization_type = NONE, not the AWS-documented AWS_IAM + CloudFront Origin Access
  # Control pattern: that combination returned a persistent 403 AccessDeniedException on
  # every request despite a correctly-configured OAC, resource policy (SourceArn-scoped),
  # and origin — see schoolsmart-terraform-47o for what was ruled out. Falls back to NONE
  # auth (publicly invokable, same network exposure as the API Gateway route's default NONE
  # authorization_type it replaces) + a shared secret CloudFront sends as a custom origin
  # header (nextjs-site.tf), which schoolsmart-admin's handler must check.
  function_url_config = {
    invoke_mode         = "RESPONSE_STREAM"
    authorization_type  = "NONE"
  }
}

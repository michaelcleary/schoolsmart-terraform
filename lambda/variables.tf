variable "env" {
  description = "Environment name"
  type        = string
}

variable "aws_account" {}

variable "aws_region" {}

variable "lambda_code_bucket" {
  description = "The name of the bucket where the lambda functions are kept"
}

variable "auth_bucket" {
  description = "The bucket where access keys are stored"
}

variable "invoices_table_stream_arn" {
  description = "The ARN of the DynamoDB stream for the invoices table"
  type        = string
}

variable "api_gateway_v2_api_id" {
  description = "The ID of the API Gateway V2 (HTTP API)"
  type        = string
  default     = ""
}

variable "email_override" {
  description = "Email override for testing (used by tutor-reminders lambda)"
  type        = string
  default     = null
}

variable "shared_services_account_id" {
}

variable "cognito_user_pool_arn" {
  description = "ARN of the Cognito User Pool (used by pre-token generation Lambda IAM policy)"
  type        = string
  default     = ""
}

variable "release_tag" {
  description = "The github sha for the release"
  type        = string
}

# nextjs_server_lambda.tf inputs — mirror what amplify.tf passes to modules/amplify so
# the OpenNext server and the (still-live, during dl3/yd1 transition) Amplify app share
# the same Cognito client and session secret.
variable "api_domain_name" {
  description = "The domain name for the API (used to build API_BASE_URL for the Next.js server lambda)"
  type        = string
}

variable "nextjs_cognito_user_pool_id" {
  description = "Cognito User Pool ID for the Next.js app"
  type        = string
}

variable "nextjs_cognito_client_id" {
  description = "Cognito App Client ID for the Next.js app"
  type        = string
}

variable "nextjs_session_secret" {
  description = "Session secret for the Next.js app (iron-session)"
  type        = string
  sensitive   = true
}

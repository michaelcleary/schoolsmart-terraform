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

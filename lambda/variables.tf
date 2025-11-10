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

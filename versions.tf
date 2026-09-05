terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      # >= 6.28.0 for aws_lambda_permission's invoked_via_function_url argument — see
      # modules/lambda/main.tf's function_url_invoke_via_url resource / schoolsmart-terraform-2b7.
      version = ">= 6.28.0"
    }
  }
}

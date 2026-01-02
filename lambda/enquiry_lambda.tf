module "enquiry_lambda" {
  source = "../modules/lambda"

  function_name = "form_handler_lambda"
  source_dir    = "./lambda/enquiry"

  env = var.env

  aws_region     = var.aws_region
  aws_account_id = var.aws_account

  # API Gateway V2 Trigger
  api_gateway_v2_config = {
    api_id     = var.api_gateway_v2_api_id
    route_keys = ["POST /submit"]
  }
}

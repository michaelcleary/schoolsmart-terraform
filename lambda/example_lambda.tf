module "example_lambda" {
  source = "../modules/lambda"

  function_name = "example-handler"
  source_dir    = "./lambda/dummy"

  env = var.env

  aws_region     = var.aws_region
  aws_account_id = var.aws_account

  # API Gateway V2 Trigger
  api_gateway_v2_config = {
    api_id     = var.api_gateway_v2_api_id
    route_keys = ["POST /example", "GET /example"]
  }
}

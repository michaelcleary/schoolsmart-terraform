resource "aws_acm_certificate" "api_cert" {
  domain_name       = "api.${var.main_domain_name}"
  validation_method = "DNS"

  tags = {
    Name        = "ACM-Certificate-API-${var.main_domain_name}"
    Environment = var.env
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "api_certificate_validation" {
  certificate_arn = aws_acm_certificate.api_cert.arn
}

resource "aws_apigatewayv2_api" "lambda_api" {
  name          = "LambdaAPI"
  protocol_type = "HTTP"
  cors_configuration {
    allow_origins = ["https://${var.main_domain_name}", "https://www.${var.main_domain_name}", "https://${var.admin_domain_name}"]
    allow_methods = ["POST", "GET", "OPTIONS"]
    allow_headers = ["content-type"]
    max_age       = 300
  }
}

resource "aws_apigatewayv2_stage" "api_stage" {
  api_id = aws_apigatewayv2_api.lambda_api.id
  name   = "$default"
  auto_deploy = true
}

# resource "aws_apigatewayv2_api" "admin_api" {
#   name          = "AdminAPI"
#   protocol_type = "HTTP"
#   cors_configuration {
#     allow_origins = ["https://${var.admin_domain_name}"]
#     allow_methods = ["POST", "GET", "OPTIONS"]
#     allow_headers = ["content-type"]
#     max_age       = 300
#   }
# }
#
# resource "aws_apigatewayv2_stage" "admin_api_stage" {
#   api_id = aws_apigatewayv2_api.admin_api.id
#   name   = "$default"
#   auto_deploy = true
# }

resource "aws_apigatewayv2_integration" "admin_api_get_integration" {
  api_id = aws_apigatewayv2_api.lambda_api.id
  integration_type = "HTTP_PROXY"
  integration_method = "GET"
  integration_uri  = format("https://%s", aws_apprunner_service.app_server.service_url)
  timeout_milliseconds = 30000
  request_parameters = {
    "overwrite:path" = "$request.path"
  }
}

resource "aws_apigatewayv2_route" "admin_api_get_route" {
  api_id = aws_apigatewayv2_api.lambda_api.id
  route_key = "GET ${var.app_runner_api_prefix}/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.admin_api_get_integration.id}"
}

resource "aws_apigatewayv2_integration" "admin_api_post_integration" {
  api_id = aws_apigatewayv2_api.lambda_api.id
  integration_type = "HTTP_PROXY"
  integration_method = "POST"
  integration_uri  = format("https://%s", aws_apprunner_service.app_server.service_url)
  timeout_milliseconds = 30000
  request_parameters = {
    "overwrite:path" = "$request.path"
  }
}

resource "aws_apigatewayv2_route" "admin_api_post_route" {
  api_id = aws_apigatewayv2_api.lambda_api.id
  route_key = "POST ${var.app_runner_api_prefix}/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.admin_api_post_integration.id}"
}

# resource "aws_apigatewayv2_route" "admin_api_route" {
#   api_id = aws_apigatewayv2_api.admin_api.id
#   route_key = "GET /admin/{proxy+}"
#   target    = "integrations/${aws_apigatewayv2_integration.admin_api_integration.id}"
# }

resource "aws_lambda_permission" "enquiry_lambda_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda.enquiry_form_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.lambda_api.execution_arn}/*"
}

resource "aws_apigatewayv2_integration" "enquiry_lambda_integration" {
  api_id = aws_apigatewayv2_api.lambda_api.id
  integration_type = "AWS_PROXY"
  integration_uri = module.lambda.enquiry_form_lambda.invoke_arn
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "enquiry_post_route" {
  api_id = aws_apigatewayv2_api.lambda_api.id
  route_key = "POST /submit"
  target    = "integrations/${aws_apigatewayv2_integration.enquiry_lambda_integration.id}"
}

resource "aws_lambda_permission" "webhooks_lambda_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda.webhooks_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.lambda_api.execution_arn}/*"
}

resource "aws_apigatewayv2_integration" "webhooks_lambda_integration" {
  api_id = aws_apigatewayv2_api.lambda_api.id
  integration_type = "AWS_PROXY"
  integration_uri = module.lambda.webhooks_lambda.invoke_arn
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "webhooks_post_route" {
  api_id = aws_apigatewayv2_api.lambda_api.id
  route_key = "POST /webhooks"
  target    = "integrations/${aws_apigatewayv2_integration.webhooks_lambda_integration.id}"
}

resource "aws_lambda_permission" "example_lambda_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda.example_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.lambda_api.execution_arn}/*"
}

resource "aws_apigatewayv2_integration" "example_lambda_integration" {
  api_id = aws_apigatewayv2_api.lambda_api.id
  integration_type = "AWS_PROXY"
  integration_uri = module.lambda.example_lambda.invoke_arn
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "example_post_route" {
  api_id = aws_apigatewayv2_api.lambda_api.id
  route_key = "POST /example"
  target    = "integrations/${aws_apigatewayv2_integration.example_lambda_integration.id}"
}

resource "aws_apigatewayv2_route" "auth_get_route" {
  api_id = aws_apigatewayv2_api.lambda_api.id
  route_key = "GET /auth/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.admin_api_get_integration.id}"
}

resource "aws_apigatewayv2_route" "auth_post_route" {
  api_id = aws_apigatewayv2_api.lambda_api.id
  route_key = "POST /auth/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.admin_api_post_integration.id}"
}

resource "aws_apigatewayv2_domain_name" "web_service_api_domain_name" {
  domain_name = "api.${var.main_domain_name}"
  domain_name_configuration {
    certificate_arn = aws_acm_certificate.api_cert.arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
  depends_on  = [
    aws_acm_certificate_validation.api_certificate_validation
  ]
}

resource "aws_apigatewayv2_api_mapping" "web_service_api_mapping" {
  api_id      = aws_apigatewayv2_api.lambda_api.id
  domain_name = aws_apigatewayv2_domain_name.web_service_api_domain_name.domain_name
  stage       = aws_apigatewayv2_stage.api_stage.id
}


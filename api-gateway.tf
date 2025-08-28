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

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.form_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.lambda_api.execution_arn}/*"
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id = aws_apigatewayv2_api.lambda_api.id
  integration_type = "AWS_PROXY"
  integration_uri = aws_lambda_function.form_lambda.invoke_arn
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "post_route" {
  api_id = aws_apigatewayv2_api.lambda_api.id
  route_key = "POST /submit"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
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


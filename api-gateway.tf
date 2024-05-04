resource "aws_apigatewayv2_api" "ndeno_dev" {
  name          = "ndeno_dev"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_authorizer" "auth" {
  api_id           = aws_apigatewayv2_api.ndeno_dev.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "cognito-authorizer"

  jwt_configuration {
    audience = [data.aws_cognito_user_pool_client.ndeno_dev_client.id]
    issuer   = "https://cognito-idp.us-east-1.amazonaws.com/${var.NDENO_DEV_USER_POOL_ID}"
  }
}

resource "aws_apigatewayv2_stage" "prod" {
  api_id = aws_apigatewayv2_api.ndeno_dev.id

  name        = "prod"
  auto_deploy = true
}

resource "aws_apigatewayv2_integration" "lambda_hello" {
  api_id = aws_apigatewayv2_api.ndeno_dev.id

  integration_uri    = aws_lambda_function.hello.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "get_hello" {
  api_id = aws_apigatewayv2_api.ndeno_dev.id

  route_key = "GET /hello"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_hello.id}"

  authorization_type = "JWT"
  authorizer_id = aws_apigatewayv2_authorizer.auth.id
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.hello.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.ndeno_dev.execution_arn}/*/*"
}

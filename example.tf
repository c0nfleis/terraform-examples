provider "aws" {
  region = "us-east-1"
}

resource "aws_api_gateway_rest_api" "the" {
  name = "example"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "the" {
  rest_api_id = aws_api_gateway_rest_api.the.id
  parent_id   = aws_api_gateway_rest_api.the.root_resource_id
  path_part   = "example"
}

resource "aws_api_gateway_model" "the" {
  rest_api_id  = aws_api_gateway_rest_api.the.id
  name         = "POSTExampleRequestModelExample"
  description  = "A JSON schema"
  content_type = "application/json"
  schema       = file("${path.module}/request_schemas/post_example.json")
}

resource "aws_api_gateway_request_validator" "the" {
  name                        = "POSTExampleRequestValidator"
  rest_api_id                 = aws_api_gateway_rest_api.the.id
  validate_request_body       = true
  validate_request_parameters = false
}

resource "aws_api_gateway_method" "the" {
  rest_api_id          = aws_api_gateway_rest_api.the.id
  resource_id          = aws_api_gateway_resource.the.id
  authorization        = "NONE"
  http_method          = "POST"
  request_validator_id = aws_api_gateway_request_validator.the.id

  request_models = {
    "application/json" = aws_api_gateway_model.the.name
  }
}

resource "aws_api_gateway_method_response" "response_200" {
  rest_api_id = aws_api_gateway_rest_api.the.id
  resource_id = aws_api_gateway_resource.the.id
  http_method = aws_api_gateway_method.the.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration" "the" {
  rest_api_id = aws_api_gateway_rest_api.the.id
  resource_id = aws_api_gateway_method.the.resource_id
  http_method = aws_api_gateway_method.the.http_method
  type        = "MOCK"
}

resource "aws_api_gateway_integration_response" "the" {
  depends_on  = [aws_api_gateway_integration.the]
  rest_api_id = aws_api_gateway_rest_api.the.id
  resource_id = aws_api_gateway_resource.the.id
  http_method = aws_api_gateway_method.the.http_method
  status_code = aws_api_gateway_method_response.response_200.status_code
}

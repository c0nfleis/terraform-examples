# JSON Request Body Validation with API Gateway in Terraform

#### This guide assumes you already have some level of familiarity with Api Gateway and Terraform. Specifically with the following resources:

- `aws_api_gateway_rest_api`
- `aws_api_gateway_resource`
- `aws_api_gateway_method`

#### In order to enforce the request payload in your api, you want to make use of the following:

- [Api Gateway Model Resource](https://www.terraform.io/docs/providers/aws/r/api_gateway_model.html)
- The `request_models` parameter for the [Terraform Api Gateway Method Resource](https://www.terraform.io/docs/providers/aws/r/api_gateway_method.html#request_models)
- [Terraform Api Gateway Request Validator Resource](https://www.terraform.io/docs/providers/aws/r/api_gateway_request_validator.html)
  - Read more about request validation with Api Gateway
- [JSON Schema](https://json-schema.org/)
  - _Note: This is **not** a guide on JSON Schema, but a guide on how to implement it for request validation using terraform_

### Step 1: Create Your REST API and Resource

```javascript
resource "aws_api_gateway_rest_api" "the" {
  name               = "example"
  binary_media_types = ["image/*"]

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "the" {
  rest_api_id = aws_api_gateway_rest_api.the.id
  parent_id   = aws_api_gateway_rest_api.the.root_resource_id
  path_part   = "example"
}
```

### Step 2: Create Your Model and Request Validator

```javascript
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
```

##### Notice, in the `schema` parameter of the `aws_api_gateway_model` I am pointing to a file. That file looks like this:

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "POST /example",
  "type": "object",
  "properties": {
    "test_bool": { "type": "boolean" },
    "test_string": { "type": "string" },
    "test_object": { "type": "object" },
    "test_int": { "type": "integer" },
    "statusCode": { "type": "integer" }
  },
  "required": ["test_bool", "test_string", "statusCode"],
  "additionalProperties": false
}
```

> Here I am defining my json schema, telling it the data types to expect in my request body in addition to the fields I want required. Last but not least I specify that if there are any additional properties, I do not want to accept the request body.

### Step 3: Create API Gateway Method and Method Response

> Note: Method Response is only required due to the backend being of type `MOCK`

```javascript
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
```

### Step 4: Create your API Gateway Integration and Integration Response

> Note: Integration Response is only required due to the backend being of type `MOCK`

```javascript
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
```

### Step 5: Test It Out

- Head on over to the API Gateway console in AWS, and find your API.

- From there, find to the POST for your path.

- You will now see a box that says "Test" with lightning bolt below it! Click It!

- On the bottom left hand corner you will see a `Request Body` field, enter your request body.

  - If you adhered one to one with my guide use these sample request bodies:

    - Bad Request

      - ```json
        {
          "test_bool": true,
          "test_string": "string",
          "test_object": { "an": "object" },
          "test_int": "Not an integer",
          "statusCode": 200
        }
        ```
      - Should return `400` and `Invalid Request Body`

    - Good Request
      - ```json
        {
          "test_bool": true,
          "test_string": "string",
          "test_object": { "an": "object" },
          "test_int": 123,
          "statusCode": 200
        }
        ```
      - Should return `200` and `no data`

I hope this helps! [Here is the link to the code in my github!](https://github.com/iNeedICS/terraform-examples)

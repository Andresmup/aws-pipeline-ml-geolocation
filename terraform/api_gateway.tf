#API GATEWAY RESOURCE
#################################################################################################################

resource "aws_api_gateway_rest_api" "rest_api_gateway" {
  name        = "rest-api-gateway-${var.app_name}-${var.app_environment}"
  description = "Rest API for data ingestion"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "data_resource" {
  rest_api_id = aws_api_gateway_rest_api.rest_api_gateway.id
  parent_id   = aws_api_gateway_rest_api.rest_api_gateway.root_resource_id
  path_part   = var.endpoint_name
}

resource "aws_api_gateway_method" "data_post" {
  rest_api_id   = aws_api_gateway_rest_api.rest_api_gateway.id
  resource_id   = aws_api_gateway_resource.data_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "kinesis_integration" {
  rest_api_id             = aws_api_gateway_rest_api.rest_api_gateway.id
  resource_id             = aws_api_gateway_resource.data_resource.id
  http_method             = aws_api_gateway_method.data_post.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:us-east-1:kinesis:action/PutRecord"

  credentials = aws_iam_role.api_gateway_role.arn

  request_templates = {
    "application/json" = <<EOF
#set($inputRoot = $input.path('$'))
{
  "StreamName": "$inputRoot.StreamName",
  "PartitionKey": "$inputRoot.PartitionKey",
  "Data": "$inputRoot.Data"
}
EOF
  }
}

resource "aws_api_gateway_method_response" "method_response" {
  rest_api_id = aws_api_gateway_rest_api.rest_api_gateway.id
  resource_id = aws_api_gateway_resource.data_resource.id
  http_method = aws_api_gateway_method.data_post.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "integration_response" {
  rest_api_id = aws_api_gateway_rest_api.rest_api_gateway.id
  resource_id = aws_api_gateway_resource.data_resource.id
  http_method = aws_api_gateway_method.data_post.http_method
  status_code = "200"

  response_templates = {
    "application/json" = ""
  }

  depends_on = [
    aws_api_gateway_integration.kinesis_integration
  ]
}

resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [
    aws_api_gateway_method.data_post,
    aws_api_gateway_integration.kinesis_integration,
    aws_api_gateway_method_response.method_response,
    aws_api_gateway_integration_response.integration_response,
  ]

  rest_api_id = aws_api_gateway_rest_api.rest_api_gateway.id
  stage_name  = var.stage_name
}

# Output the deploy URL of the API Gateway
output "api_gateway_url" {
  description = "API Gateway deploy URL"
  value       = aws_api_gateway_deployment.deployment.invoke_url
}


#API GATEWAY IAM
#################################################################################################################

resource "aws_iam_policy" "kinesis_put_record_policy" {
  name = "producer-kinesis-${var.app_name}-${var.app_environment}-policy"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AllowPutRecordTestStreamConsole",
        "Effect" : "Allow",
        "Action" : "kinesis:PutRecord",
        "Resource" : "${aws_kinesis_stream.kinesis_data_stream.arn}"
      }
    ]
  })
}

resource "aws_iam_role" "api_gateway_role" {
  name = "api-gateway-${var.app_name}-${var.app_environment}-role"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AllowAssumeApiGateway",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "apigateway.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })

}

resource "aws_iam_role_policy_attachment" "api_gateway_attach" {
  role       = aws_iam_role.api_gateway_role.name
  policy_arn = aws_iam_policy.kinesis_put_record_policy.arn
}
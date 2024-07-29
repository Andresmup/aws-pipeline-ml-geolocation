#LAMBDA TRANSFORMATION RESOURCE
#################################################################################################################

# Define the Lambda function for transformation
resource "aws_lambda_function" "lambda_firehose_transformation" {
  function_name = "lambda-transformation-${var.app_name}-${var.app_environment}"
  role          = aws_iam_role.lambda_firehose_transformation_role.arn
  handler       = var.lambda_handler
  runtime       = var.python_runtime
  timeout       = 60
  filename      = "deploy_transformation.zip"

}

#LAMBDA TRANSFORMATION IAM
#################################################################################################################

resource "aws_iam_role" "lambda_firehose_transformation_role" {
  name = "lambda-firehose-transformation-${var.app_name}-${var.app_environment}-role"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "lambda.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_cloudwatch_policy" {
  name = "lambda-logs-cloudwatch-${var.app_name}-${var.app_environment}-policy"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : "*"
      }
    ]
  })
}

#Attach lambda_cloudwatch_policy
resource "aws_iam_role_policy_attachment" "attach-lambda-firehose-custom-managed-cloudwatch-policy" {
  role       = aws_iam_role.lambda_firehose_transformation_role.name
  policy_arn = aws_iam_policy.lambda_cloudwatch_policy.arn
}


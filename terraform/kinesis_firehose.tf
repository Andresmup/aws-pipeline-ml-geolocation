#FIREHOSE RESOURCE
#################################################################################################################

resource "aws_kinesis_firehose_delivery_stream" "firehose" {
  name        = "firehose-${var.app_name}-${var.app_environment}"
  destination = "extended_s3"

  kinesis_source_configuration {
    kinesis_stream_arn = aws_kinesis_stream.kinesis_data_stream.arn
    role_arn           = aws_iam_role.kinesis_firehose_role.arn
  }


  extended_s3_configuration {
    role_arn   = aws_iam_role.kinesis_firehose_role.arn
    bucket_arn = aws_s3_bucket.bucket_raw_data.arn

    buffering_size     = 64
    buffering_interval = 60

    dynamic_partitioning_configuration {
      enabled = true
    }

    # Prefix using partitionKeys from Lambda metadata
    prefix              = "input_records/year=!{partitionKeyFromLambda:year}/month=!{partitionKeyFromLambda:month}/day=!{partitionKeyFromLambda:day}"
    error_output_prefix = "errors/!{firehose:error-output-type}/"

    #Processing
    processing_configuration {
      enabled = true

      processors {
        type = "Lambda"
        parameters {
          parameter_name  = "LambdaArn"
          parameter_value = "${aws_lambda_function.lambda_firehose_transformation.arn}:$LATEST"
        }
      }

      processors {
        type = "AppendDelimiterToRecord"
      }
    }

    data_format_conversion_configuration {
      input_format_configuration {
        deserializer {
          hive_json_ser_de {

          }
        }
      }

      output_format_configuration {
        serializer {
          parquet_ser_de {
            compression = var.parquet_compression_format
          }
        }
      }

      schema_configuration {
        database_name = aws_glue_catalog_database.catalog_database.name
        role_arn      = aws_iam_role.kinesis_firehose_role.arn
        table_name    = aws_glue_catalog_table.aws_glue_table.name
      }
    }
  }
}


#FIREHOSE IAM
#################################################################################################################

resource "aws_iam_role" "kinesis_firehose_role" {
  name = "kinesis-firehose-${var.app_name}-${var.app_environment}-role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Principal" : {
          "Service" : [
            "firehose.amazonaws.com"
          ]
        },
        "Effect" : "Allow",
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "firehose_multi_statement_policy" {
  name = "firehose-multi-statement-${var.app_name}-${var.app_environment}-policy"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AllowAccessS3Bucket",
        "Effect" : "Allow",
        "Action" : [
          "s3:AbortMultipartUpload",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:PutObject"
        ],
        "Resource" : [
          "${aws_s3_bucket.bucket_raw_data.arn}",
          "${aws_s3_bucket.bucket_raw_data.arn}/*"
        ]
      },
      {
        "Sid" : "CloudwatchAccess"
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : "*"
      },
      {
        "Sid" : "GetRecordsKinesis",
        "Effect" : "Allow",
        "Action" : [
          "kinesis:SubscribeToShard",
          "kinesis:DescribeStreamSummary",
          "kinesis:ListShards",
          "kinesis:GetShardIterator",
          "kinesis:GetRecords",
          "kinesis:DescribeStream"
        ],
        "Resource" : "${aws_kinesis_stream.kinesis_data_stream.arn}"
      },
      {
        "Sid" : "ListStreamsKinesis",
        "Effect" : "Allow",
        "Action" : "kinesis:ListStreams",
        "Resource" : "*"
      },
      {
        "Sid" : "AllowGlueSchemaAccess",
        "Effect" : "Allow",
        "Action" : [
          "glue:GetTable",
          "glue:GetTableVersion",
          "glue:GetTableVersions",
          "glue:GetSchema",
          "glue:GetSchemaVersion",
          "glue:GetSchemaVersionsDiff"
        ],
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_iam_policy" "firehose_lambda_policy" {
  name = "firehose-lambda-orders-${var.app_name}-${var.app_environment}-policy"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "lambda:InvokeFunction",
          "lambda:GetFunctionConfiguration"
        ],
        "Resource" : "${aws_lambda_function.lambda_firehose_transformation.arn}:*"
      }
    ]
  })
}

resource "aws_iam_policy" "firehose_put_policy" {
  name = "firehose-put-${var.app_name}-${var.app_environment}-policy"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "firehose:PutRecord",
          "firehose:PutRecordBatch"
        ],
        "Resource" : [
          "${aws_kinesis_firehose_delivery_stream.firehose.arn}"
        ]
      }
    ]
  })
}

#Attach multi-statement policies
resource "aws_iam_role_policy_attachment" "attach-firehose-base-policies" {
  role       = aws_iam_role.kinesis_firehose_role.name
  policy_arn = aws_iam_policy.firehose_multi_statement_policy.arn
}

#Attach put policy
resource "aws_iam_role_policy_attachment" "attach-firehose-put-policies" {
  role       = aws_iam_role.kinesis_firehose_role.name
  policy_arn = aws_iam_policy.firehose_put_policy.arn
}

#Attach firehose_lambda_policy
resource "aws_iam_role_policy_attachment" "attach-firehose-lambda-policy" {
  role       = aws_iam_role.kinesis_firehose_role.name
  policy_arn = aws_iam_policy.firehose_lambda_policy.arn
}


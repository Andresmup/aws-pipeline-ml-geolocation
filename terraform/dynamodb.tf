resource "aws_dynamodb_table" "dynamodb_table" {
  name           = "temporary-${var.app_name}-${var.app_environment}-table"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "unique_timestamp"

  attribute {
    name = "unique_timestamp"
    type = "S"
  }

  ttl {
    attribute_name = "TimeToExist"
    enabled        = true
  }

}
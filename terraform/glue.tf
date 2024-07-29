#GLUE DATABASE RESOURCE
#################################################################################################################

resource "aws_glue_catalog_database" "catalog_database" {
  name = "catalog-${var.app_name}-${var.app_environment}-database"
}


#GLUE TABLE RAW DATA
#################################################################################################################

resource "aws_glue_catalog_table" "aws_glue_table" {
  name          = "raw-data-${var.app_name}-${var.app_environment}-table"
  database_name = aws_glue_catalog_database.catalog_database.name

  table_type = "EXTERNAL_TABLE"

  parameters = {
    EXTERNAL              = "TRUE"
    "parquet.compression" = "${var.parquet_compression_format}"
  }

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.bucket_raw_data.id}/input_records/"
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"

    ser_de_info {
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"

      parameters = {
        "serialization.format" = 1
      }
    }

    columns {
      name = "timestamp"
      type = "string"
    }

    columns {
      name = "latitude"
      type = "string"
    }

    columns {
      name = "longitude"
      type = "string"
    }

  }

}
#KINESIS RESOURCE
#################################################################################################################

resource "aws_kinesis_stream" "kinesis_data_stream" {
  name = "${var.app_name}-${var.app_environment}-stream"

  shard_level_metrics = [
    "IncomingBytes",
    "OutgoingBytes",
  ]

  stream_mode_details {
    stream_mode = "ON_DEMAND"
  }

}

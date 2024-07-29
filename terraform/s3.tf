#S3 RAW DATA BUCKET RESOURCE
#################################################################################################################

resource "aws_s3_bucket" "bucket_raw_data" {
  bucket = "raw-data-${var.app_name}-${var.app_environment}"

  force_destroy = true
  lifecycle {
    prevent_destroy = false
  }
}

#S3 RAW DATA BUCKET IAM
#################################################################################################################

resource "aws_iam_policy" "bucket_upload_policy" {
  name = "upload-bucket-raw-data-${var.app_name}-${var.app_environment}-policy"

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
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:PutObject"
        ],
        "Resource" : [
          "${aws_s3_bucket.bucket_raw_data.arn}",
          "${aws_s3_bucket.bucket_raw_data.arn}/*"
        ]
      }
    ]
  })

}

#S3 AIRFLOW BUCKET RESOURCE
#################################################################################################################

resource "aws_s3_bucket" "bucket_airflow_resources" {
  bucket = "airflow-resources-${var.app_name}-${var.app_environment}"

  force_destroy = true
  lifecycle {
    prevent_destroy = false
  }
}

resource "null_resource" "upload_files" {
  provisioner "local-exec" {
    command = "aws s3 cp ../airflow_resources/ s3://${aws_s3_bucket.bucket_airflow_resources.bucket} --recursive"
  }

  depends_on = [aws_s3_bucket.bucket_airflow_resources]
}


#S3 AIRFLOW BUCKET IAM
#################################################################################################################

resource "aws_iam_policy" "s3_update_object_policy" {
  name = "s3-update-object-${var.app_name}-${var.app_environment}-policy"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "PutObject",
        "Effect" : "Allow",
        "Action" : "s3:PutObject",
        "Resource" : [
          "arn:aws:s3:::${aws_s3_bucket.bucket_airflow_resources.bucket}/*"
        ]
      },
      {
        "Sid" : "ListBucket",
        "Effect" : "Allow",
        "Action" : "s3:ListBucket",
        "Resource" : [
          "arn:aws:s3:::${aws_s3_bucket.bucket_airflow_resources.bucket}"
        ]
      }
    ]
  })
}


resource "aws_iam_role" "github_actions_role" {
  name = "github-actions-${var.app_name}-${var.app_environment}-role"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Federated" : "arn:aws:iam::${var.account_id}:oidc-provider/token.actions.githubusercontent.com"
        },
        "Action" : "sts:AssumeRoleWithWebIdentity",
        "Condition" : {
          "StringEquals" : {
            "token.actions.githubusercontent.com:aud" : "sts.amazonaws.com"
          },
          "StringLike" : {
            "token.actions.githubusercontent.com:sub" : "repo:${var.github_org}/${var.repository_name}:*"
          }
        }
      }
    ]
  })
}

#Attach s3_update_object_policy
resource "aws_iam_role_policy_attachment" "attach-github-action--s3-policy" {
  role       = aws_iam_role.github_actions_role.name
  policy_arn = aws_iam_policy.s3_update_object_policy.arn
}


# Output the ARN of Github Action role
output "github_action_s3_update_object_role_arn" {
  description = "Github action machine role ARN"
  value       = aws_iam_role.github_actions_role.arn
}
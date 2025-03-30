provider "aws" {
  region = "us-east-1"  # CUR reports must be in us-east-1
}

# Create S3 bucket for CUR reports
resource "aws_s3_bucket" "cur_reports" {
  bucket = "atlan-cur-reports-${random_id.bucket_suffix.hex}"
  acl    = "private"

  lifecycle {
    prevent_destroy = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

# Random suffix for bucket name
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# S3 bucket policy for CUR delivery
resource "aws_s3_bucket_policy" "cur_policy" {
  bucket = aws_s3_bucket.cur_reports.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "billingreports.amazonaws.com"
      },
      "Action": [
        "s3:GetBucketAcl",
        "s3:GetBucketPolicy"
      ],
      "Resource": "${aws_s3_bucket.cur_reports.arn}"
    },
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "billingreports.amazonaws.com"
      },
      "Action": "s3:PutObject",
      "Resource": "${aws_s3_bucket.cur_reports.arn}/*"
    }
  ]
}
POLICY
}

# Create the Cost and Usage Report
resource "aws_cur_report_definition" "atlan_cur" {
  report_name                = "AtlanCostUsageReport"
  time_unit                  = "DAILY"
  format                     = "Parquet"  # Recommended for Athena
  compression                = "Parquet"
  additional_schema_elements = ["RESOURCES"]
  s3_bucket                  = aws_s3_bucket.cur_reports.bucket
  s3_prefix                  = "cur-reports"
  s3_region                  = "us-east-1"
  report_versioning          = "OVERWRITE_REPORT"

  depends_on = [aws_s3_bucket_policy.cur_policy]
}

# Set up Athena database and table for CUR queries
resource "aws_glue_catalog_database" "cur_database" {
  name = "atlan_cost_analysis"
}

resource "aws_glue_catalog_table" "cur_table" {
  name          = "cost_and_usage"
  database_name = aws_glue_catalog_database.cur_database.name

  table_type = "EXTERNAL_TABLE"

  parameters = {
    EXTERNAL              = "TRUE"
    "parquet.compression" = "SNAPPY"
  }

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.cur_reports.bucket}/cur-reports/"
    input_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"

    ser_de_info {
      name                  = "cur-ser-de"
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"

      parameters = {
        "serialization.format" = "1"
      }
    }

    columns {
      name = "identity_line_item_id"
      type = "string"
    }
    columns {
      name = "bill_billing_period_start_date"
      type = "timestamp"
    }
    # Add all other CUR columns as needed...
    # See AWS CUR schema for complete list
  }
}

# Athena workgroup for cost analysis
resource "aws_athena_workgroup" "cost_analysis" {
  name = "cost-analysis"

  configuration {
    enforce_workgroup_configuration = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${aws_s3_bucket.cur_reports.bucket}/athena-results/"

      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }
}

# IAM policy for Athena CUR access
resource "aws_iam_policy" "athena_cur_access" {
  name        = "AthenaCURAccess"
  description = "Allows querying CUR data in Athena"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "athena:*",
        "glue:GetDatabase",
        "glue:GetTable",
        "glue:GetTables",
        "glue:GetPartition",
        "glue:GetPartitions"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "${aws_s3_bucket.cur_reports.arn}",
        "${aws_s3_bucket.cur_reports.arn}/*"
      ]
    }
  ]
}
EOF
}

output "cur_bucket_name" {
  value = aws_s3_bucket.cur_reports.bucket
}

output "athena_database_name" {
  value = aws_glue_catalog_database.cur_database.name
}

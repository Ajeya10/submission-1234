# main.tf for Cost Tracking
provider "aws" {
  region = "us-east-1"
}

# Create S3 bucket for Cost and Usage Reports
resource "aws_s3_bucket" "cur_bucket" {
  bucket = "atlan-cur-reports-${random_id.bucket_suffix.hex}"
  acl    = "private"
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Enable Cost and Usage Report
resource "aws_cur_report_definition" "atlan_cur" {
  report_name                = "AtlanCostUsageReport"
  time_unit                  = "DAILY"
  format                     = "textORcsv"
  compression                = "GZIP"
  additional_schema_elements = ["RESOURCES"]
  s3_bucket                  = aws_s3_bucket.cur_bucket.bucket
  s3_region                  = "us-east-1"
  s3_prefix                  = "cur"
  report_versioning          = "OVERWRITE_REPORT"
}

# Create AWS Budget
resource "aws_budgets_budget" "monthly_cost" {
  name              = "monthly-cost-budget"
  budget_type       = "COST"
  limit_amount      = "1000"
  limit_unit        = "USD"
  time_period_start = "2023-01-01_00:00"
  time_unit         = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = ["team@atlan.com"]
  }
}

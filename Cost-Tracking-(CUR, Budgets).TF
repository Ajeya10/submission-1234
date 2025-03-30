provider "aws" {
  region = "us-east-1" # Modify as needed
}

# --- AWS Cost & Usage Report (CUR) ---
resource "aws_cur_report_definition" "cost_usage_report" {
  report_name          = "daily-cost-usage-report"
  time_unit           = "DAILY"
  format              = "textORcsv"
  compression         = "GZIP"
  additional_schema_elements = ["RESOURCES"]
  s3_bucket           = aws_s3_bucket.cost_reports.bucket
  s3_prefix           = "reports"
  s3_region           = "us-east-1"
  report_versioning   = "OVERWRITE_REPORT"
}

resource "aws_s3_bucket" "cost_reports" {
  bucket = "cost-usage-reports-bucket-${random_id.suffix.hex}"
  acl    = "private"
  force_destroy = true
}

resource "random_id" "suffix" {
  byte_length = 4
}

# --- AWS Budgets ---
resource "aws_budgets_budget" "monthly_cost_budget" {
  name              = "monthly-cost-budget"
  budget_type       = "COST"
  limit_amount      = "1000" # Set your budget threshold (e.g., $1000)
  limit_unit        = "USD"
  time_unit         = "MONTHLY"

  notification {
    comparison_operator = "GREATER_THAN"
    threshold           = 80 # Alert at 80% of budget
    threshold_type      = "PERCENTAGE"
    notification_type   = "ACTUAL"
    subscriber_email_addresses = ["team@example.com"] # Replace with your email
  }
}

# --- IAM Role for Cost Explorer Access ---
resource "aws_iam_role" "cost_explorer_role" {
  name = "CostExplorerReadOnlyRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "cost-explorer.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "cost_explorer_policy" {
  name        = "CostExplorerReadOnlyPolicy"
  description = "Allows read-only access to AWS Cost Explorer"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "ce:GetCostAndUsage",
          "ce:GetCostForecast"
        ],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cost_explorer_attach" {
  role       = aws_iam_role.cost_explorer_role.name
  policy_arn = aws_iam_policy.cost_explorer_policy.arn
}

# --- Outputs ---
output "cur_bucket_name" {
  value = aws_s3_bucket.cost_reports.bucket
}

output "budget_name" {
  value = aws_budgets_budget.monthly_cost_budget.name
}

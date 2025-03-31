# 1. Create SNS Topic for alerts
resource "aws_sns_topic" "cost_alerts" {
  name = "atlan-cost-alerts-topic"
  
  tags = {
    Environment = "production"
    CostCenter  = "cloud-optimization"
  }
}

# 2. Subscribe email/slack to SNS
resource "aws_sns_topic_subscription" "email_alerts" {
  topic_arn = aws_sns_topic.cost_alerts.arn
  protocol  = "email"
  endpoint  = "team@atlan.com" # Replace with your email
}

# 3. Create IAM Role for Budget Actions
resource "aws_iam_role" "budget_action" {
  name = "atlan-budget-action-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "budgets.amazonaws.com"
      }
    }]
  })
}

# 4. Attach required permissions
resource "aws_iam_role_policy_attachment" "budget_action" {
  role       = aws_iam_role.budget_action.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCostAndUsageReportFullAccess"
}

# 5. Create Budget Action
resource "aws_budgets_budget_action" "anomaly_detection" {
  budget_name        = aws_budgets_budget.monthly_cost.name
  action_type        = "APPLY_IAM_POLICY"
  notification_type  = "ACTUAL"
  approval_model     = "AUTOMATIC"
  execution_role_arn = aws_iam_role.budget_action.arn

  action_threshold {
    action_threshold_value = 100
    action_threshold_type = "ABSOLUTE_VALUE"
  }

  definition {
    iam_action_definition {
      policy_arn = "arn:aws:iam::aws:policy/AWSCostAndUsageReportFullAccess"
      roles      = [aws_iam_role.budget_action.name]
    }
  }

  subscriber {
    address           = aws_sns_topic.cost_alerts.arn
    subscription_type = "SNS"
  }
}

# 6. CloudWatch Alarm for high spend
resource "aws_cloudwatch_metric_alarm" "high_spend" {
  alarm_name          = "high-spend-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "EstimatedCharges"
  namespace          = "AWS/Billing"
  period             = 21600 # 6 hours
  statistic          = "Maximum"
  threshold          = 500
  alarm_description  = "Alerts when AWS charges exceed $500"
  alarm_actions      = [aws_sns_topic.cost_alerts.arn]
}

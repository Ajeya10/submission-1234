# main.tf for Alerting
resource "aws_sns_topic" "cost_alerts" {
  name = "atlan-cost-alerts"
}

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

resource "aws_cloudwatch_metric_alarm" "high_spend" {
  alarm_name          = "high-spend-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "EstimatedCharges"
  namespace          = "AWS/Billing"
  period             = "21600" # 6 hours
  statistic          = "Maximum"
  threshold          = "500"
  alarm_description  = "Alerts when AWS charges exceed $500"
  alarm_actions      = [aws_sns_topic.cost_alerts.arn]
}

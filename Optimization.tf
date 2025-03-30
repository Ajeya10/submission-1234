# main.tf for Optimization
resource "aws_autoscaling_policy" "scale_down" {
  name                   = "scale-down-policy"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.example.name
}

resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name          = "low-cpu-utilization"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace          = "AWS/EC2"
  period             = "300"
  statistic          = "Average"
  threshold          = "30"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.example.name
  }
  alarm_description = "Scale down when CPU < 30% for 10 minutes"
  alarm_actions     = [aws_autoscaling_policy.scale_down.arn]
}

# Enable Compute Optimizer for the account
resource "aws_computeoptimizer_enrollment_status" "atlan" {
  status = "Active"
}

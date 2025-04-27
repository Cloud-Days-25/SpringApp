# SNS Topic for billing alarm notifications
resource "aws_sns_topic" "billing_alarm" {
  name = "billing-alarm-topic"
  
  tags = var.common_tags
}

# SNS Topic subscription - replace with your email address
resource "aws_sns_topic_subscription" "billing_alarm_email" {
  topic_arn = aws_sns_topic.billing_alarm.arn
  protocol  = "email"
  endpoint  = var.alarm_email  # This will be your email address defined in variables.tf
}

# CloudWatch billing alarm for $0 spend
resource "aws_cloudwatch_metric_alarm" "billing_alarm" {
  alarm_name          = "billing-alarm-$0"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = 21600  # 6 hours
  statistic           = "Maximum"
  threshold           = 0.01   # $0.01 - essentially detecting any charges
  alarm_description   = "Billing alarm triggered when charges exceed $0.01"
  alarm_actions       = [aws_sns_topic.billing_alarm.arn]
  
  dimensions = {
    Currency = "USD"
  }

  tags = var.common_tags
}
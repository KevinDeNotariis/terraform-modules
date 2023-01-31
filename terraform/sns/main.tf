# ---------------------------------------------------------------
# 1. Create the Topic for General Info
# ---------------------------------------------------------------
resource "aws_sns_topic" "general" {
  name = "${local.identifier}-general-${var.suffix}"
}

# ---------------------------------------------------------------
# 2. Create the SNS subscription
# ---------------------------------------------------------------
resource "aws_sns_topic_subscription" "general" {
  for_each = {
    for sns_general_sub in var.sns_general_subs : sns_general_sub.endpoint => sns_general_sub
  }

  topic_arn = aws_sns_topic.general.arn
  protocol  = each.value.protocol
  endpoint  = each.value.endpoint
}

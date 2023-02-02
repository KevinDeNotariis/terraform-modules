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
    for sns_general_sub in var.sns_general_subscriptions : sns_general_sub.endpoint => sns_general_sub
  }

  topic_arn = aws_sns_topic.general.arn
  protocol  = each.value.protocol
  endpoint  = each.value.endpoint
}

# ---------------------------------------------------------------
# 3. Add the Policy to the SNS
# ---------------------------------------------------------------
data "aws_iam_policy_document" "general" {
  statement {
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.general.arn]
    principals {
      type = "Service"
      identifiers = [
        "codestar-notifications.amazonaws.com",
        "events.amazonaws.com"
      ]
    }
  }
}

resource "aws_sns_topic_policy" "general" {
  arn    = aws_sns_topic.general.arn
  policy = data.aws_iam_policy_document.general.json
}

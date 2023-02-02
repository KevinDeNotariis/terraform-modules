# ---------------------------------------------------------------
# 1. Define the Application Autoscaling Target
# ---------------------------------------------------------------
resource "aws_appautoscaling_target" "this" {
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${var.ecs_cluster_name}/${var.ecs_service_name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# ---------------------------------------------------------------
# 2. Define the Application Autoscaling Policies
# ---------------------------------------------------------------
resource "aws_appautoscaling_policy" "memory" {
  name               = "${local.identifier}-memory-${var.suffix}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.this.resource_id
  scalable_dimension = aws_appautoscaling_target.this.scalable_dimension
  service_namespace  = aws_appautoscaling_target.this.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value = var.scaling_memory_trigger
  }
}
resource "aws_appautoscaling_policy" "cpu" {
  name               = "${local.identifier}-cpu-${var.suffix}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.this.resource_id
  scalable_dimension = aws_appautoscaling_target.this.scalable_dimension
  service_namespace  = aws_appautoscaling_target.this.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = var.scaling_cpu_trigger
  }
}

# ---------------------------------------------------------------
# 3. Create an Event Rule for Scaling Activities
# ---------------------------------------------------------------
resource "aws_cloudwatch_event_rule" "this" {
  name        = "${local.identifier}-app-autoscaling-${var.suffix}"
  description = "Catch Application Autoscaling Events"
  event_pattern = jsonencode({
    source      = ["aws.application-autoscaling"]
    detail-type = ["Application Auto Scaling Scaling Activity State Change"]
  })

  tags = local.tags
}

# ---------------------------------------------------------------
# 4. Set SNS as the Target of the Autoscaling events
# ---------------------------------------------------------------
resource "aws_cloudwatch_event_target" "this" {
  rule = aws_cloudwatch_event_rule.this.name
  arn  = var.scaling_sns_arn
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "lambda_function.py"
  output_path = "lambda_function.zip"
}

resource "aws_lambda_function" "configurator" {
  function_name    = "${var.prefix}-lifecycle-hook-handler"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.11"
  filename         = data.archive_file.lambda_zip.output_path
  
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      ALLOWED_ASG_PREFIXES = var.prefix
      ALLOWED_ASGS         = var.allowed_asgs
      HEARTBEAT_TIMEOUT    = var.heartbeat_timeout
      LIFECYCLE_HOOK_NAME  = var.lifecycle_hook_name
    }
  }
}

resource "aws_cloudwatch_event_rule" "asg_create" {
  name = "${var.prefix}-asg-create-rule"
  event_pattern = jsonencode({
    "detail-type": ["AWS API Call via CloudTrail"],
    "detail": {
      "eventSource": ["autoscaling.amazonaws.com"],
      "eventName":   ["CreateAutoScalingGroup"]
    }
  })
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule = aws_cloudwatch_event_rule.asg_create.name
  arn  = aws_lambda_function.configurator.arn
}

resource "aws_lambda_permission" "allow_eb" {
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.configurator.function_name
  principal = "events.amazonaws.com"
  source_arn = aws_cloudwatch_event_rule.asg_create.arn
}

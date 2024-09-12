data "archive_file" "this" {
  type        = "zip"
  source_file = "./LogGenerator/index.py"
  output_path = "./LogGenerator/lambda.zip"
}

# resource "aws_cloudwatch_log_group" "this" {
#   name = "${local.project}-log-group"
  
#   retention_in_days = 14

#   tags = {
#     Name = "auditlogs"
#   }
# }

# resource "aws_cloudwatch_log_stream" "this" {
#   name           = "${local.project}-log-stream"
#   log_group_name = aws_cloudwatch_log_group.this.name
# }

resource "aws_cloudwatch_event_rule" "this" {
  name        = "${local.project}-audit-rule"

  schedule_expression = "rate(1 minute)"
}

resource "aws_cloudwatch_event_target" "this" {
  rule      = aws_cloudwatch_event_rule.this.name
  target_id = "TriggerLambda"
  arn       = aws_lambda_function.lambda_function.arn
}

resource "aws_iam_role" "lambda" {
  name = var.lambda.role_name
 
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      },
      Action = ["sts:AssumeRole"]
    }]
  })
}

resource "aws_iam_policy" "lambda" {
  name = var.lambda.policy_name
 
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "logs:CreateLogStream",
          "logs:CreateLogGroup",
          "logs:PutLogEvents"
        ],
        Effect   = "Allow",
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "function_logging_policy_attachment" {
  role       = aws_iam_role.lambda.id
  policy_arn = aws_iam_policy.lambda.arn
}

resource "aws_lambda_function" "lambda_function" {
  filename      = "./lambda.zip"
  function_name = "test_lambda_logs"
  role          = aws_iam_role.lambda.arn
  handler       = "index.lambda_handler"
  runtime       = "python3.12"
  timeout       = 900
  environment {
    variables = {
      log_group_name  = "${local.log_group_name}"
      log_stream_name = "${local.log_stream_name}"
      log_throuput    =  "${local.log_throuput}"
    }
  }
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AWSEvents_trigger-lambda"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.lambda_function.function_name}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.this.arn}"
}

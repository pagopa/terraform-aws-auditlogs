data "archive_file" "lambda" {
  type        = "zip"
  source_file = "./LogGenerator/index.py"
  output_path = "./LogGenerator/lambda.zip"
}

resource "aws_iam_role" "lambda" {
  name = "${local.project}-auditlogs-lambda-role"

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
  name = "${local.project}-auditlogs-lambda-policy"

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

resource "aws_iam_role_policy_attachment" "lambda" {
  role       = aws_iam_role.lambda.id
  policy_arn = aws_iam_policy.lambda.arn
}

resource "aws_lambda_function" "lambda" {
  depends_on = [data.archive_file.lambda]

  function_name = "${local.project}-auditlogs-lambda"
  filename      = "./LogGenerator/lambda.zip"
  role          = aws_iam_role.lambda.arn
  handler       = "index.lambda_handler"
  runtime       = "python3.12"
  timeout       = 900
  environment {
    variables = {
      log_group_name  = "${local.project}-auditlogs-group"
      log_stream_name = "${local.project}-auditlogs-stream"
      log_throuput    = "1000"
    }
  }
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AWSEvents_trigger-lambda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.lambda.arn
}

resource "aws_cloudwatch_event_rule" "lambda" {
  name                = "${local.project}-auditlogs-rule"
  schedule_expression = "rate(1 minute)"
  is_enabled          = false
}

resource "aws_cloudwatch_event_target" "lambda" {
  rule      = aws_cloudwatch_event_rule.lambda.name
  target_id = "TriggerLambda"
  arn       = aws_lambda_function.lambda.arn
}

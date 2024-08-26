data "aws_caller_identity" "current" {}


data "archive_file" "this" {
  type        = "zip"
  source_file = "./index.py"
  output_path = "./lambda.zip"
}

resource "random_integer" "audit_bucket_suffix" {
  min = 1000
  max = 9999
}

locals {
  bucket_name = format("%s-%s", "auditlogs",
    random_integer.audit_bucket_suffix.result
  )
}

resource "aws_cloudwatch_log_group" "this" {
  name = "auditlogs"

  retention_in_days = 14

  tags = {
    Name = "auditlogs"
  }
}

resource "aws_cloudwatch_log_stream" "this" {
  name           = "SampleLogStream"
  log_group_name = aws_cloudwatch_log_group.this.name
}

resource "aws_kinesis_stream" "this" {
  name             = "log-group-stream"
  shard_count      = 0
  retention_period = 48

  stream_mode_details {
    stream_mode = "ON_DEMAND"
  }

  tags = {
    Name = "auditlogs"
  }
}

module "s3_assets_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.1.1"

  bucket = local.bucket_name
  acl    = "private"

  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  tags = {
    Name = "auditlogs"
  }
}

resource "aws_iam_role" "cloudwatchRole" {
  name = "cloudwatchRole_auditLogs"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = ["sts:AssumeRole"],
        Principal = {
          Service = "logs.amazonaws.com"
        },
        Effect = "Allow",
        Sid    = ""
      }
    ]
  })
}

resource "aws_iam_policy" "cloudwatch_kinesis" {
  name_prefix = "CloudwtachToKinesis_auditLogs"
  policy = jsonencode({

    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "",
        Effect = "Allow",
        Action = [
          "kinesis:PutRecord"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cloudwatch_kinesis" {
  role       = aws_iam_role.cloudwatchRole.name
  policy_arn = aws_iam_policy.cloudwatch_kinesis.arn
}

resource "aws_cloudwatch_log_subscription_filter" "this" {
  name            = "test_lambdafunction_logfilter"
  role_arn        = aws_iam_role.cloudwatchRole.arn
  log_group_name  = aws_cloudwatch_log_group.this.name
  filter_pattern  = ""
  destination_arn = aws_kinesis_stream.this.arn
}

resource "aws_iam_role" "firehoseRole" {
  name = "firehoseRole_auditLogs"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = ["sts:AssumeRole"],
        Principal = {
          "Service" : "firehose.amazonaws.com"
        },
        Effect = "Allow",
        Sid    = ""
      }
    ]
  })
}

resource "aws_iam_policy" "firehose_kinesis" {
  name_prefix = "FirehoseToKinesis_auditLogs"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "",
        Effect = "Allow",
        Action = [
          "kinesis:DescribeStream",
          "kinesis:GetShardIterator",
          "kinesis:GetRecords",
          "kinesis:ListShards"
        ],
        Resource = "${aws_kinesis_stream.this.arn}"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "firehose_kinesis" {
  role       = aws_iam_role.firehoseRole.name
  policy_arn = aws_iam_policy.firehose_kinesis.arn
}


resource "aws_kinesis_firehose_delivery_stream" "demo_delivery_stream" {
  name        = "firehose-delivery"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehoseRole.arn
    bucket_arn = module.s3_assets_bucket.s3_bucket_arn
    //file_extension = ".json"

    # dynamic_partitioning_configuration {
    #   enabled = true
    # }
  }

  kinesis_source_configuration {
    kinesis_stream_arn = aws_kinesis_stream.this.arn
    role_arn           = aws_iam_role.firehoseRole.arn
  }

  tags = {
    Product = "Demo"
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"
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

resource "aws_iam_policy" "function_logging_policy" {
  name = "function-logging-policy"
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
  role       = aws_iam_role.iam_for_lambda.id
  policy_arn = aws_iam_policy.function_logging_policy.arn
}

resource "aws_lambda_function" "lambda_function" {
  filename      = "./lambda.zip"
  function_name = "test_lambda_logs"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "index.lambda_handler"
  depends_on    = [aws_cloudwatch_log_group.this]
  runtime       = "python3.12"
  environment {
    variables = {
      log_group_name  = "${aws_cloudwatch_log_group.this.name}"
      log_stream_name = "${aws_cloudwatch_log_stream.this.name}"
    }
  }
}


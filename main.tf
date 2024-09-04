data "aws_caller_identity" "current" {}


data "archive_file" "this" {
  type        = "zip"
  source_file = "./index.py"
  output_path = "./lambda.zip"
}

resource "random_id" "unique" {
  byte_length = 3
}

resource "random_integer" "audit_bucket_suffix" {
  min = 1000
  max = 9999
}

locals {
  bucket_name = format("%s-%s", "auditlogs",
    random_integer.audit_bucket_suffix.result
  )
  athena_outputs = format("query-%s", local.bucket_name)
  project = "auditLogs-es-d-${random_id.unique.hex}"
}

resource "aws_cloudwatch_log_group" "this" {
  name = "${local.project}-log-group"
  
  retention_in_days = 14

  tags = {
    Name = "auditlogs"
  }
}

resource "aws_cloudwatch_log_stream" "this" {
  name           = "${local.project}-log-stream"
  log_group_name = aws_cloudwatch_log_group.this.name
}

resource "aws_kinesis_stream" "this" {
  name             = "${local.project}-kinesis-stream"
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
  name = "${local.project}-cloudwatch-role"

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
          "kinesis:PutRecord",
          "kinesis:PutRecords"
        ],
        Resource = "${aws_kinesis_stream.this.arn}"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cloudwatch_kinesis" {
  role       = aws_iam_role.cloudwatchRole.name
  policy_arn = aws_iam_policy.cloudwatch_kinesis.arn
}

resource "aws_cloudwatch_log_subscription_filter" "this" {
  name            = "${local.project}-lambda-log"
  role_arn        = aws_iam_role.cloudwatchRole.arn
  log_group_name  = aws_cloudwatch_log_group.this.name
  filter_pattern  = "{ $.audit = \"true\" }"
  destination_arn = aws_kinesis_stream.this.arn
}

resource "aws_iam_role" "firehoseRole" {
  name = "${local.project}-firehoseRole"

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
          "kinesis:ListShards",
          "kinesis:ListStreams"
        ],
        Resource = "${aws_kinesis_stream.this.arn}"
      },
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject"
        ],
        Resource = "${module.s3_assets_bucket.s3_bucket_arn}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "firehose_kinesis" {
  role       = aws_iam_role.firehoseRole.name
  policy_arn = aws_iam_policy.firehose_kinesis.arn
}


resource "aws_kinesis_firehose_delivery_stream" "demo_delivery_stream" {
  name        = "${local.project}-firehose-delivery"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehoseRole.arn
    bucket_arn = module.s3_assets_bucket.s3_bucket_arn
    prefix     = "logs/"

    processing_configuration {
      enabled = "true"
      processors {
        type = "Decompression"
        parameters {
          parameter_name  = "CompressionFormat"
          parameter_value = "GZIP"
        }
      }
    }
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

module "s3_athena_output_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.1.1"

  bucket = local.athena_outputs
  acl    = "private"

  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  tags = {
    Name = local.bucket_name
  }
}

resource "aws_athena_workgroup" "audit_workgroup" {
  name = "audit_workgroup"

  configuration {
    result_configuration {
      output_location = "s3://${local.athena_outputs}/output/"
    }
  }
}

# Create Athena database
resource "aws_athena_database" "audit" {
  name   = "auditlogsathenadb"
  bucket = module.s3_athena_output_bucket.s3_bucket_id
}

data "aws_iam_policy_document" "glue_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["glue.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "glue_audit" {
  name               = "AWSGlueServiceRole-AuditLogs"
  assume_role_policy = data.aws_iam_policy_document.glue_assume_role_policy.json
  path               = "/service-role/"
}

data "aws_iam_policy_document" "glue_audit_policy" {
  statement {
    sid       = "S3ReadAndWrite"
    effect    = "Allow"
    resources = ["arn:aws:s3:::${module.s3_assets_bucket.s3_bucket_id}/*"]
    actions   = ["s3:GetObject", "s3:PutObject"]
  }
}

resource "aws_iam_policy" "glue_audit_policy" {
  name        = "AWSGlueServiceRoleAuditS3Policy"
  description = "S3 bucket audit policy for glue."
  policy      = data.aws_iam_policy_document.glue_audit_policy.json
}

locals {
  glue_audit_policy = [
    "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole",
    aws_iam_policy.glue_audit_policy.arn,
  ]
}

resource "aws_iam_role_policy_attachment" "glue_s3_audit_policy" {
  count      = length(local.glue_audit_policy)
  role       = aws_iam_role.glue_audit.name
  policy_arn = local.glue_audit_policy[count.index]

}

resource "aws_glue_catalog_database" "audit" {
  name = "audit"
}

#Check multiple tables creation
resource "aws_glue_crawler" "audit" {
  database_name = aws_glue_catalog_database.audit.name
  name          = "audit"
  role          = aws_iam_role.glue_audit.arn

  description = "Crawler for the audit bucket"
  schedule    = var.audit_crawler_schedule
  configuration = jsonencode(
    {
      # CrawlerOutput = {
      #   Tables = {
      #     TableThreshold = 1
      #   }
      # }
       
      # CreatePartitionIndex = true
      Grouping = {
        TableGroupingPolicy = "CombineCompatibleSchemas"
      }
      Version              = 1.0

    }
  )

  s3_target {
    path = "s3://${module.s3_assets_bucket.s3_bucket_id}/logs"
  }
}


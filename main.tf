resource "aws_cloudwatch_log_group" "this" {
  name              = var.cloudwatch.log_group_name
  retention_in_days = 14
}

resource "aws_cloudwatch_log_stream" "this" {
  name           = var.cloudwatch.log_stream_name
  log_group_name = aws_cloudwatch_log_group.this.name
}

resource "aws_kinesis_stream" "this" {
  name             = var.kinesis.stream_name
  shard_count      = 0
  retention_period = 240

  stream_mode_details {
    stream_mode = "ON_DEMAND"
  }
}

module "s3_assets_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.1.1"

  bucket = var.s3.bucket_name
  acl    = "private"

  control_object_ownership = true
  object_ownership         = "ObjectWriter"
}

resource "aws_iam_role" "cloudwatch_kinesis" {
  name = var.cloudwatch.role_name

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
  name_prefix = var.cloudwatch.policy_name

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
  role       = aws_iam_role.cloudwatch_kinesis.name
  policy_arn = aws_iam_policy.cloudwatch_kinesis.arn
}

resource "aws_cloudwatch_log_subscription_filter" "this" {
  name            = var.cloudwatch.subscription_filter_name
  role_arn        = aws_iam_role.cloudwatch_kinesis.arn
  log_group_name  = var.cloudwatch.log_group_name
  filter_pattern  = var.cloudwatch.filter_pattern
  destination_arn = aws_kinesis_stream.this.arn
}

resource "aws_iam_role" "firehose" {
  name = var.firehose.role_name

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
  name_prefix = var.firehose.policy_name

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
  role       = var.firehose.role_name
  policy_arn = aws_iam_policy.firehose_kinesis.arn
}


resource "aws_kinesis_firehose_delivery_stream" "firehose" {
  name        = var.firehose.delivery_stream_name
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn            = aws_iam_role.firehose.arn
    bucket_arn          = module.s3_assets_bucket.s3_bucket_arn
    prefix              = "logs/year_!{timestamp:yyyy}/month_!{timestamp:MM}/day_!{timestamp:dd}/"
    error_output_prefix = "errors/year_!{timestamp:yyyy}/month_!{timestamp:MM}/day_!{timestamp:dd}/!{firehose:error-output-type}/"

    processing_configuration {
      enabled = "true"
      processors {
        type = "Decompression"
        parameters {
          parameter_name  = "CompressionFormat"
          parameter_value = "GZIP"
        }
      }
      processors {
        type = "AppendDelimiterToRecord"
      }
    }
    file_extension = ".json"
  }

  kinesis_source_configuration {
    kinesis_stream_arn = aws_kinesis_stream.this.arn
    role_arn           = aws_iam_role.firehose.arn
  }
}

resource "aws_athena_workgroup" "this" {
  name = var.athena.workgroup_name
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
  name               = var.glue.role_name
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
  name        = var.glue.policy_name
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
  name = var.glue.database_name
}

#Check multiple tables creation
resource "aws_glue_crawler" "audit" {
  database_name = var.glue.database_name
  name          = var.glue.crawler_name
  role          = aws_iam_role.glue_audit.arn

  description = "Crawler for the audit bucket"
  schedule    = var.glue.crawler_schedule
  configuration = jsonencode(
    {
      Grouping = {
        TableGroupingPolicy = "CombineCompatibleSchemas",
      }
      CrawlerOutput = {
        Partitions = { AddOrUpdateBehavior = "InheritFromTable" }
      }
      Version = 1
    }
  )

  s3_target {
    path = "s3://${module.s3_assets_bucket.s3_bucket_id}/logs"
  }
}

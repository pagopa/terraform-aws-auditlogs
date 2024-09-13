data "aws_caller_identity" "current" {}


# data "archive_file" "this" {
#   type        = "zip"
#   source_file = "./index.py"
#   output_path = "./lambda.zip"
# }

resource "random_id" "unique" {
  byte_length = 3
}



# locals {
#   bucket_name = format("%s-%s", var.s3_bucket_name,
#     random_integer.audit_bucket_suffix.result
#   )
#   athena_outputs = format("query-%s", var.s3_bucket_name)
#   project = "auditLogs-es-d-${random_id.unique.hex}"
# }

resource "aws_cloudwatch_log_group" "this" {
  name = var.cloudwatch.log_group_name

  retention_in_days = 14

  tags = {
    Name = "auditlogs"
  }
}

resource "aws_cloudwatch_log_stream" "this" {
  name           = var.cloudwatch.log_stream_name
  log_group_name = aws_cloudwatch_log_group.this.name
}

resource "aws_kinesis_stream" "this" {
  name             = var.kinesis_stream_name
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

  bucket = var.s3_bucket_name
  acl    = "private"

  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  tags = {
    Name = "auditlogs"
  }
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
  name           = var.cloudwatch.subscription_filter_name
  role_arn       = aws_iam_role.cloudwatch_kinesis.arn
  log_group_name = var.cloudwatch.log_group_name
  filter_pattern = var.cloudwatch.filter_pattern
  #"{ $.audit = \"true\" }"
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


resource "aws_kinesis_firehose_delivery_stream" "demo_delivery_stream" {
  name        = var.firehose.stream_name
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

  tags = {
    Product = "Demo"
  }
}

# resource "aws_iam_role" "lambda" {
#   name = var.lambda.role_name

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [{
#       Effect = "Allow",
#       Principal = {
#         Service = "lambda.amazonaws.com"
#       },
#       Action = ["sts:AssumeRole"]
#     }]
#   })
# }

# resource "aws_iam_policy" "lambda" {
#   name = var.lambda.policy_name

#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Action = [
#           "logs:CreateLogStream",
#           "logs:CreateLogGroup",
#           "logs:PutLogEvents"
#         ],
#         Effect   = "Allow",
#         Resource = "arn:aws:logs:*:*:*"
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "function_logging_policy_attachment" {
#   role       = aws_iam_role.lambda.id
#   policy_arn = aws_iam_policy.lambda.arn
# }

# resource "aws_lambda_function" "lambda_function" {
#   filename      = "./lambda.zip"
#   function_name = "test_lambda_logs"
#   role          = aws_iam_role.lambda.arn
#   handler       = "index.lambda_handler"
#   depends_on    = [aws_cloudwatch_log_group.this]
#   runtime       = "python3.12"
#   environment {
#     variables = {
#       log_group_name  = "${aws_cloudwatch_log_group.this.name}"
#       log_stream_name = "${aws_cloudwatch_log_stream.this.name}"
#     }
#   }
# }

# module "s3_athena_output_bucket" {
#   source  = "terraform-aws-modules/s3-bucket/aws"
#   version = "4.1.1"

#   bucket = var.athena_output
#   acl    = "private"

#   control_object_ownership = true
#   object_ownership         = "ObjectWriter"
# }

resource "aws_athena_workgroup" "audit_workgroup" {
  name = var.athena_workgroup_name

  # configuration {
  #   result_configuration {
  #     output_location = "s3://${var.athena_output}/output/"
  #   }
  # }
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
  schedule    = var.audit_crawler_schedule
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

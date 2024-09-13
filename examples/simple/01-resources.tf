resource "random_integer" "audit_bucket_suffix" {
  min = 1000
  max = 9999
}

module "aws_auditlogs" {
  source = "../.."

  cloudwatch = {
    filter_pattern           = "{ $.audit = \"true\" }",
    log_group_name           = "${local.project}-audit-log-group",           #Optional
    log_stream_name          = "${local.project}-audit-log-stream",          #Optional
    subscription_filter_name = "${local.project}-audit-subscription-filter", #Optional
    role_name                = "${local.project}-audit-cloudwatch-role-name" #Optional
  }

  s3_bucket_name = "${local.project}-audit-s3-bucket" #Optional

  athena_workgroup_name = "${local.project}-audit-workgroup" #Optional

  glue = {
    crawler_name  = "${local.project}-audit-crawler", #Optional
    database_name = "${local.project}-audit-database" #Optional
  }

  kinesis_stream_name = "${local.project}-audit-kinesis-stream" #Optional

  firehose = {
    stream_name = "${local.project}-audit-firehose-stream" #Optional
  }
}
resource "random_integer" "audit_bucket_suffix" {
  min = 1000
  max = 9999
}

module "aws_auditlogs" {
  source              = "../.."
  
  cloudwatch = {
    filter_pattern = "{ $.audit = \"true\" }",
    log_group_name = "${local.project}-log-group",
    log_stream_name = "${local.project}-log-stream",
    subscription_filter_name = "${local.project}-subscription-filter"
    role_name  = "${local.project}-cloudwatch-role-name" #Optional
  }

  s3_bucket_name =  "${local.project}-s3-bucket"

  athena_workgroup_name = "${local.project}-workgroup"

  glue = {
    crawler_name = "${local.project}-crawler",
    database_name = "${local.project}-database"
  }

  kinesis_stream_name = "${local.project}-kinesis-stream"

  firehose = {
    stream_name = "${local.project}-firehose-stream"
  }

  lambda = {
    role_name = "${local.project}-lambda-role-name"
    policy_name =  "${local.project}-lambda-policy-name"
  }
}

module "aws_auditlogs" {
  source = "../.."

  cloudwatch = {
    filter_pattern           = "{ $.audit = \"true\" }",
    log_group_name           = "${local.project}-auditlogs-group",               # Optional
    log_stream_name          = "${local.project}-auditlogs-stream",              # Optional
    subscription_filter_name = "${local.project}-auditlogs-subscription-filter", # Optional
    role_name                = "${local.project}-cloudwatch-kinesis-role",       # Optional
    policy_name              = "${local.project}-cloudwtach-kinesis-policy",     # Optional
    # additional_log_groups = {
    #   test_log_group1 = {
    #     subscription_filter_name = "auditlogs-subscription-filter1"
    #     log_group_name = "auditlogs-group1"
    #     filter_pattern = "{ $.audit = \"true\" }"
    #   },
    #   test_log_group2 = {
    #     subscription_filter_name = "auditlogs-subscription-filter2"
    #     log_group_name =  "auditlogs-group2"
    #     filter_pattern = "{ $.audit = \"true\" }"
    #   }
    # }

  }

  s3 = {
    bucket_name         = "${local.project}-auditlogs-s3-bucket" # Optional
    object_lock_enabled = false
    retention_days      = 3
  }

  athena = {
    workgroup_name = "${local.project}-auditlogs-athena-workgroup" # Optional
  }

  glue = {
    crawler_name     = "${local.project}-auditlogs-glue-crawler", # Optional
    crawler_schedule = "cron(0 5 * * ? *)",
    database_name    = "${local.project}-auditlogs-glue-database" # Optional
    role_name        = "${local.project}-auditlogs-glue-role",    # Optional
    policy_name      = "${local.project}-auditlogs-glue-policy",  # Optional
  }

  kinesis = {
    stream_name = "${local.project}-auditlogs-kinesis-stream" # Optional
  }

  firehose = {
    stream_name          = "${local.project}-auditlogs-firehose-stream", # Optional
    delivery_stream_name = "${local.project}-firehose-delivery-stream",  # Optional
    role_name            = "${local.project}-firehose-role",             # Optional
    policy_name          = "${local.project}-firehose-kinesis-policy",   # Optional
  }
}

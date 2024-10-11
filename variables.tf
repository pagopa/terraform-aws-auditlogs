variable "cloudwatch" {
  type = object({
    log_group_name           = optional(string, "auditlogs-log-group"),
    log_stream_name          = optional(string, "auditlogs-log-stream"),
    subscription_filter_name = optional(string, "auditlogs-subscription-filter"),
    filter_pattern           = optional(string, "{ $.audit = \"true\" }", ),
    role_name                = optional(string, "auditlogs-cloudwatch-firehose-role"),
    policy_name              = optional(string, "auditlogs-cloudwtach-firehose-policy"),
    additional_log_groups = optional(map(object({
      log_group_name           = string
      filter_pattern           = string
      subscription_filter_name = string
    })), {})

  })
}

variable "s3" {
  type = object({
    bucket_name         = optional(string, "auditlogs-s3-bucket")
    object_lock_enabled = bool
    retention_days      = number
  })
}

variable "athena" {
  type = object({
    workgroup_name = optional(string, "auditlogs-athena-workgroup")
  })
}

variable "glue" {
  type = object({
    crawler_name     = optional(string, "auditlogs-glue-crawler"),
    crawler_schedule = optional(string, "cron(0 5 * * ? *)"),
    database_name    = optional(string, "auditlogs-glue-database"),
    role_name        = optional(string, "auditlogs-glue-role"),
    policy_name      = optional(string, "auditlogs-glue-policy"),
  })
}

variable "firehose" {
  type = object({
    delivery_stream_name = optional(string, "auditlogs-firehose-delivery-stream")
    role_name            = optional(string, "auditlogs-firehose-role"),
    policy_name          = optional(string, "auditlogs-firehose-kinesis-policy")
  })
}

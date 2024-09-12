variable "audit_crawler_schedule" {
  type        = string
  description = "A cron expression used to specify the schedule"
  default     = "cron(0 5 * * ? *)"
}

variable "cloudwatch" {
  type = object({
    log_group_name           = string,
    log_stream_name          = string,
    subscription_filter_name = string
    filter_pattern           = string
    role_name                = optional(string, "audit-logs-cloudwatch-kinesis-role"),
    policy_name              = optional(string, "audit-logs-cloudwtach-kinesis-policy")
  })
}

variable "s3_bucket_name" {
  type = string
}

variable "athena_workgroup_name" {
  type = string
}

variable "glue" {
  type = object({
    crawler_name       = string,
    database_name      = string,
    role_name          = optional(string, "audit-logs-glue-role"),
    policy_name        = optional(string, "audit-logs-glue-policy")
  })
}

variable "kinesis_stream_name" {
  type = string
}

variable "firehose" {
  type = object({
    stream_name = string,
    role_name   = optional(string,"audit-logs-firehose-role"),
    policy_name = optional(string,"audit-logs-firehose-kinesis-policy")
  })
}




variable "audit_crawler_schedule" {
  type        = string
  description = "A cron expression used to specify the schedule"
  default     = "cron(0 5 * * ? *)"
}
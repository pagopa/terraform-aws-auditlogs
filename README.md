# terraform-aws-auditlogs<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7.4 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.65.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_s3_assets_bucket"></a> [s3\_assets\_bucket](#module\_s3\_assets\_bucket) | terraform-aws-modules/s3-bucket/aws | 4.1.1 |

## Resources

| Name | Type |
|------|------|
| [aws_athena_workgroup.audit_workgroup](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/athena_workgroup) | resource |
| [aws_cloudwatch_log_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_stream.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_stream) | resource |
| [aws_cloudwatch_log_subscription_filter.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_subscription_filter) | resource |
| [aws_glue_catalog_database.audit](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/glue_catalog_database) | resource |
| [aws_glue_crawler.audit](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/glue_crawler) | resource |
| [aws_iam_policy.cloudwatch_kinesis](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.firehose_kinesis](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.glue_audit_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.cloudwatch_kinesis](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.firehose](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.glue_audit](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.cloudwatch_kinesis](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.firehose_kinesis](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.glue_s3_audit_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_kinesis_firehose_delivery_stream.demo_delivery_stream](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kinesis_firehose_delivery_stream) | resource |
| [aws_kinesis_stream.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kinesis_stream) | resource |
| [random_id.unique](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.glue_assume_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.glue_audit_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_athena_workgroup_name"></a> [athena\_workgroup\_name](#input\_athena\_workgroup\_name) | n/a | `string` | n/a | yes |
| <a name="input_audit_crawler_schedule"></a> [audit\_crawler\_schedule](#input\_audit\_crawler\_schedule) | A cron expression used to specify the schedule | `string` | `"cron(0 5 * * ? *)"` | no |
| <a name="input_cloudwatch"></a> [cloudwatch](#input\_cloudwatch) | n/a | <pre>object({<br>    log_group_name           = string,<br>    log_stream_name          = string,<br>    subscription_filter_name = string<br>    filter_pattern           = string<br>    role_name                = optional(string, "audit-logs-cloudwatch-kinesis-role"),<br>    policy_name              = optional(string, "audit-logs-cloudwtach-kinesis-policy")<br>  })</pre> | n/a | yes |
| <a name="input_firehose"></a> [firehose](#input\_firehose) | n/a | <pre>object({<br>    stream_name = string,<br>    role_name   = optional(string, "audit-logs-firehose-role"),<br>    policy_name = optional(string, "audit-logs-firehose-kinesis-policy")<br>  })</pre> | n/a | yes |
| <a name="input_glue"></a> [glue](#input\_glue) | n/a | <pre>object({<br>    crawler_name  = string,<br>    database_name = string,<br>    role_name     = optional(string, "audit-logs-glue-role"),<br>    policy_name   = optional(string, "audit-logs-glue-policy")<br>  })</pre> | n/a | yes |
| <a name="input_kinesis_stream_name"></a> [kinesis\_stream\_name](#input\_kinesis\_stream\_name) | n/a | `string` | n/a | yes |
| <a name="input_s3_bucket_name"></a> [s3\_bucket\_name](#input\_s3\_bucket\_name) | n/a | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

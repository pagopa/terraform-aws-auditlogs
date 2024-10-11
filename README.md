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
| <a name="module_s3_workgroup_name_bucket"></a> [s3\_workgroup\_name\_bucket](#module\_s3\_workgroup\_name\_bucket) | terraform-aws-modules/s3-bucket/aws | 4.1.1 |

## Resources

| Name | Type |
|------|------|
| [aws_athena_workgroup.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/athena_workgroup) | resource |
| [aws_cloudwatch_log_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_stream.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_stream) | resource |
| [aws_cloudwatch_log_subscription_filter.additional](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_subscription_filter) | resource |
| [aws_cloudwatch_log_subscription_filter.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_subscription_filter) | resource |
| [aws_glue_catalog_database.audit](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/glue_catalog_database) | resource |
| [aws_glue_crawler.audit](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/glue_crawler) | resource |
| [aws_iam_policy.cloudwatch_firehose](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.firehose_s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.glue_audit_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.cloudwatch_firehose](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.firehose](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.glue_audit](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.cloudwatch_firehose](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.firehose_s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.glue_s3_audit_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_kinesis_firehose_delivery_stream.firehose](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kinesis_firehose_delivery_stream) | resource |
| [aws_s3_bucket_lifecycle_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_object_lock_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_object_lock_configuration) | resource |
| [aws_iam_policy_document.glue_assume_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.glue_audit_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_athena"></a> [athena](#input\_athena) | n/a | <pre>object({<br/>    workgroup_name = optional(string, "auditlogs-athena-workgroup")<br/>  })</pre> | n/a | yes |
| <a name="input_cloudwatch"></a> [cloudwatch](#input\_cloudwatch) | n/a | <pre>object({<br/>    log_group_name           = optional(string, "auditlogs-log-group"),<br/>    log_stream_name          = optional(string, "auditlogs-log-stream"),<br/>    subscription_filter_name = optional(string, "auditlogs-subscription-filter"),<br/>    filter_pattern           = optional(string, "{ $.audit = \"true\" }", ),<br/>    role_name                = optional(string, "auditlogs-cloudwatch-firehose-role"),<br/>    policy_name              = optional(string, "auditlogs-cloudwtach-firehose-policy"),<br/>    additional_log_groups = optional(map(object({<br/>      log_group_name           = string<br/>      filter_pattern           = string<br/>      subscription_filter_name = string<br/>    })), {})<br/><br/>  })</pre> | n/a | yes |
| <a name="input_firehose"></a> [firehose](#input\_firehose) | n/a | <pre>object({<br/>    delivery_stream_name = optional(string, "auditlogs-firehose-delivery-stream")<br/>    role_name            = optional(string, "auditlogs-firehose-role"),<br/>    policy_name          = optional(string, "auditlogs-firehose-kinesis-policy")<br/>  })</pre> | n/a | yes |
| <a name="input_glue"></a> [glue](#input\_glue) | n/a | <pre>object({<br/>    crawler_name     = optional(string, "auditlogs-glue-crawler"),<br/>    crawler_schedule = optional(string, "cron(0 5 * * ? *)"),<br/>    database_name    = optional(string, "auditlogs-glue-database"),<br/>    role_name        = optional(string, "auditlogs-glue-role"),<br/>    policy_name      = optional(string, "auditlogs-glue-policy"),<br/>  })</pre> | n/a | yes |
| <a name="input_s3"></a> [s3](#input\_s3) | n/a | <pre>object({<br/>    bucket_name         = optional(string, "auditlogs-s3-bucket")<br/>    object_lock_enabled = bool<br/>    retention_days      = number<br/>  })</pre> | n/a | yes |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

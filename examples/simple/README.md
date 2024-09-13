# terraform-aws-auditlogs: Simple example



<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | 1.9.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.65.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_aws_auditlogs"></a> [aws\_auditlogs](#module\_aws\_auditlogs) | ../.. | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_event_rule.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_iam_policy.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lambda_function.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_permission.allow_cloudwatch](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [random_id.unique](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [archive_file.lambda](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | n/a | `string` | `"eu-south-1"` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | Resorce prefix | `string` | `"adl"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Audit Log Solution | `map(string)` | <pre>{<br>  "CreatedBy": "Terraform"<br>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_project"></a> [project](#output\_project) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

variable "aws_region" {
  type    = string
  default = "eu-south-1"
}

variable "tags" {
  type        = map(string)
  description = "Audit Log Solution"
  default = {
    CreatedBy   = "Terraform"
    Description = "Support Request with Stram Analytics and Immutability"
  }
}

variable "prefix" {
  description = "Resorce prefix"
  type        = string
  default     = "adl"
}

variable "lambda" {
  type = object({
    role_name   = optional(string),
    policy_name = optional(string)
  })
  default = {
    role_name   = "audit-logs-lambda-role",
    policy_name = "audit-logs-lambda-policy"
  }
}


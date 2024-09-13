variable "aws_region" {
  type    = string
  default = "eu-south-1"
}

variable "tags" {
  type        = map(string)
  description = "Audit Log Solution"
  default = {
    CreatedBy = "Terraform"
  }
}

variable "prefix" {
  description = "Resorce prefix"
  type        = string
  default     = "adl"
}

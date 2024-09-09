variable "location" {
  type    = string
  default = "italynorth"
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
  default     = "auditLogs-es-d"
}

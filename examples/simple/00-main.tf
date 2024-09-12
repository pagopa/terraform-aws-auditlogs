terraform {
  required_version = "1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.65.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = var.tags
  }
}

resource "random_id" "unique" {
  byte_length = 3
}

locals {
  project         = "${var.prefix}-${random_id.unique.hex}"
  log_group_name  = "${local.project}-audit-log-group"
  log_stream_name = "${local.project}-audit-log-stream"
  log_throuput    = 1000
}

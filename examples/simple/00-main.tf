terraform {
  required_version = "1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.65.0"
    }
  }

  backend "s3" {
    bucket         = "terraform-backend-20230207141844477000000001"
    key            = "auditlogs/main/tfstate"
    region         = "eu-south-1"
    dynamodb_table = "terraform-lock"
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
  project = "${var.prefix}-${random_id.unique.hex}"
}

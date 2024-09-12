terraform {
  backend "s3" {
    bucket         = "terraform-backend-20230207141844477000000001"
    key            = "auditlogs/main/tfstate"
    region         = "eu-south-1"
    dynamodb_table = "terraform-lock"
  }
}
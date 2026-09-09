terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Remote state - S3 bucket + DynamoDB lock table must exist before first init.
  # Create them once manually (or with a small bootstrap tf config), then never
  # touch this block per-run — backend config can't use variables.
  backend "s3" {
    bucket         = "REPLACE-ME-terraform-state-bucket"
    key            = "prod/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "REPLACE-ME-terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}

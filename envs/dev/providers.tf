terraform {
  required_version = ">= 1.10.0" # required for S3 native locking (use_lockfile)

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Remote state - only the S3 bucket needs to exist before first init.
  # No DynamoDB table needed: use_lockfile makes Terraform use S3's own
  # conditional writes (If-None-Match) to create/remove a .tflock file
  # alongside the state, which is what actually enforces the lock.
  backend "s3" {
    bucket       = "REPLACE-ME-terraform-state-bucket"
    key          = "dev/terraform.tfstate"
    region       = "ap-south-1"
    use_lockfile = true
    encrypt      = true
  }
}

provider "aws" {
  region = var.aws_region
}

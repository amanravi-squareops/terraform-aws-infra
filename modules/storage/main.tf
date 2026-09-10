############################################
# S3 bucket for the backend service's own data
# (uploads, generated files, logs) - separate
# from the Terraform state bucket.
############################################
resource "aws_s3_bucket" "app_data" {
  bucket        = "${var.project_name}-${var.environment}-app-data"
  force_destroy = var.force_destroy

  tags = {
    Name        = "${var.project_name}-${var.environment}-app-data"
    Environment = var.environment
  }
}

# Nobody can make this bucket public, even by accident
resource "aws_s3_bucket_public_access_block" "app_data" {
  bucket = aws_s3_bucket.app_data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "app_data" {
  bucket = aws_s3_bucket.app_data.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "app_data" {
  bucket = aws_s3_bucket.app_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Auto-cleanup old versions after 90 days so storage cost doesn't creep up
resource "aws_s3_bucket_lifecycle_configuration" "app_data" {
  bucket = aws_s3_bucket.app_data.id

  rule {
    id     = "expire-old-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

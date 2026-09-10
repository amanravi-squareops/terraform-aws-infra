output "bucket_name" {
  value = aws_s3_bucket.app_data.bucket
}

output "bucket_arn" {
  value = aws_s3_bucket.app_data.arn
}

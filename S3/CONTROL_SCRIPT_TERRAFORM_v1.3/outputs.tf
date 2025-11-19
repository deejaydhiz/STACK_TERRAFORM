output "bucket_name" {
  value       = aws_s3_bucket.this.bucket
  description = "S3 bucket name"
}

output "region" {
  value       = var.bucket_region
  description = "AWS region where the bucket is created"
}

output "bucket_arn" {
  value       = aws_s3_bucket.this.arn
  description = "S3 bucket ARN"
}

output "bucket_domain_name" {
  value       = aws_s3_bucket.this.bucket_domain_name
  description = "S3 regional DNS name"
}

output "bucket_sse_algorithm" {
  value       = var.default_encryption
  description = "Default bucket encryption algorithm"
}

output "bucket_kms_key_arn" {
  value       = var.kms_key_arn
  description = "KMS key used for default encryption (if aws:kms)"
}

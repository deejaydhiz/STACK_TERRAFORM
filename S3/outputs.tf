output "bucket_name"        { value = aws_s3_bucket.this.bucket }
output "bucket_arn"         { value = aws_s3_bucket.this.arn }
output "bucket_domain_name" { value = aws_s3_bucket.this.bucket_domain_name }
output "website_endpoint"   { value = try(aws_s3_bucket_website_configuration.this[0].website_endpoint, null) }

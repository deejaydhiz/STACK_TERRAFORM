resource "aws_s3_bucket_accelerate_configuration" "example" {
  bucket = aws_s3_bucket.this.id
  status = "Enabled"
}
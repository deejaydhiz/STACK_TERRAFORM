# Trail writing to the SAME bucket (or set a different one)
resource "aws_cloudtrail" "this" {
  count                         = var.enable_cloudtrail_data_events ? 1 : 0
  name                          = "${var.bucket_name}-trail"
  s3_bucket_name                = aws_s3_bucket.this.bucket
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_logging                = true

  event_selector {
    read_write_type           = "All"
    include_management_events = true
    data_resource {
      type   = "AWS::S3::Object"
      values = ["${aws_s3_bucket.this.arn}/"]
    }
  }
}


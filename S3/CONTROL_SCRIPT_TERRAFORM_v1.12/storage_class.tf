# Storage class analysis for S3 bucket, exporting to a new analytics bucket

resource "aws_s3_bucket_analytics_configuration" "tf-entire-bucket" {
  bucket = aws_s3_bucket.this.id
  name   = "EntireBucket-tf"
  filter {
    prefix = ""

    tags = {
      desc = "Entire Bucket storage class-analysis"
      mode = "Terraform"
    }
  }
  storage_class_analysis {
    data_export {
      destination {
        s3_bucket_destination {
          bucket_arn = aws_s3_bucket.analytics.arn
          format     = "CSV"
        }
      }
    }
  }
}

resource "aws_s3_bucket" "analytics" {
  bucket = "storage-class-analytics-dest-deji"
  force_destroy = var.force_destroy
}
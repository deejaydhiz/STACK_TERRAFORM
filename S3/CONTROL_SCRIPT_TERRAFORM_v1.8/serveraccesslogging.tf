# --- SERVER ACCESS LOGGING CONFIGURATION ---

# Create a dedicated access-log bucket when enabled and none provided
resource "aws_s3_bucket" "logs" {
  count  = var.enable_server_access_logging && var.logs_bucket_name == null ? 1 : 0
  bucket = "${aws_s3_bucket.this.bucket}-access-logging"
  tags   = var.tags
}

# Bucket policy to allow S3 Log Delivery service to write logs
data "aws_iam_policy_document" "logging_bucket_policy" {
  statement {
    principals {
      identifiers = ["logging.s3.amazonaws.com"]
      type        = "Service"
    }
    actions = ["s3:PutObject"]
    resources = [
      "${var.logs_bucket_name != null ? "arn:aws:s3:::${var.logs_bucket_name}" : aws_s3_bucket.logs[0].arn}/*"
    ]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_s3_bucket_policy" "logs" {
  count  = var.enable_server_access_logging ? 1 : 0
  bucket = var.logs_bucket_name != null ? var.logs_bucket_name : aws_s3_bucket.logs[0].id
  policy = data.aws_iam_policy_document.logging_bucket_policy.json
}

# --- Enable logging on the SOURCE bucket ---
resource "aws_s3_bucket_logging" "this" {
  count         = var.enable_server_access_logging ? 1 : 0
  bucket        = aws_s3_bucket.this.id
  target_bucket = var.logs_bucket_name != null ? var.logs_bucket_name : aws_s3_bucket.logs[0].id
  target_prefix = var.logs_prefix
  target_object_key_format {
    partitioned_prefix {
      partition_date_source = "EventTime"
    }
  }
  #depends_on = [
  # aws_s3_bucket_policy.logs,
  #aws_s3_bucket_public_access_block.this,   # from earlier stories
  # aws_s3_bucket_ownership_controls.this     # your source bucket ownership controls
  #]
}

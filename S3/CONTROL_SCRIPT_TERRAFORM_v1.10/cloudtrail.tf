data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_partition" "current" {}

# Create the CloudTrail log bucket only if data events are enabled AND
# the user didn't provide an existing bucket.
resource "aws_s3_bucket" "ct_logs" {
  count         = var.enable_cloudtrail_data_events && var.cloudtrail_log_bucket_name == null ? 1 : 0
  bucket        = "${var.cloudtrail_trail_name}-logs-${data.aws_caller_identity.current.account_id}"
  tags          = var.tags
  force_destroy = true # allow bucket to be destroyed with contents
}

# If user provided an external log bucket, look it up (early validation).
data "aws_s3_bucket" "external_ct_logs" {
  count  = var.cloudtrail_log_bucket_name != null ? 1 : 0
  bucket = var.cloudtrail_log_bucket_name
}

# ---- Safe resolution of bucket name/arn (no hard indexing) ----
locals {
  # Only touch aws_s3_bucket.ct_logs[0] if we actually created it
  ct_logs_bucket_name = (
    var.cloudtrail_log_bucket_name != null
    ? var.cloudtrail_log_bucket_name
    : (
      var.enable_cloudtrail_data_events
      ? aws_s3_bucket.ct_logs[0].id
      : null
    )
  )

  ct_logs_bucket_arn = (
    var.cloudtrail_log_bucket_name != null
    ? "arn:aws:s3:::${var.cloudtrail_log_bucket_name}"
    : (
      var.enable_cloudtrail_data_events
      ? aws_s3_bucket.ct_logs[0].arn
      : null
    )
  )
}

# ---- Bucket policy for CloudTrail writes (count depends only on var) ----
data "aws_iam_policy_document" "ct_logs" {
  count = var.enable_cloudtrail_data_events ? 1 : 0

  # Allow CloudTrail to PutObject with bucket-owner-full-control
  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["s3:PutObject"]
    resources = ["${local.ct_logs_bucket_arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }

  # Allow CloudTrail to GetBucketAcl and GetBucketLocation
  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["s3:GetBucketAcl", "s3:GetBucketLocation"]
    resources = [local.ct_logs_bucket_arn]
  }
}

resource "aws_s3_bucket_policy" "ct_logs" {
  count  = var.enable_cloudtrail_data_events ? 1 : 0
  bucket = local.ct_logs_bucket_name
  policy = data.aws_iam_policy_document.ct_logs[0].json

  # If we created the log bucket, ensure it exists first.
  depends_on = [aws_s3_bucket.ct_logs]
}

# ---- CloudTrail with S3 object-level data events ----
resource "aws_cloudtrail" "s3_data_events" {
  count                         = var.enable_cloudtrail_data_events ? 1 : 0
  name                          = var.cloudtrail_trail_name
  s3_bucket_name                = local.ct_logs_bucket_name
  is_multi_region_trail         = true
  include_global_service_events = true
  enable_logging                = true
  kms_key_id                    = null

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["${aws_s3_bucket.this.arn}/"] # trailing slash required
    }
  }

  depends_on = [
    aws_s3_bucket_policy.ct_logs, # ensure policy applied before trail starts logging
  ]
}


############################
# S3 BUCKET: CREATE + CONFIG
############################
resource "aws_s3_bucket" "this" {
  bucket        = var.bucket_name
  force_destroy = var.force_destroy   # allows emptying/deleting via destroy
  tags          = merge(var.tags, { ManagedBy = "terraform" })

  # Object Lock requires enabling at CREATE time
  object_lock_enabled = var.enable_object_lock
}

# Object ownership / ACL behavior
resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id
  rule {
    object_ownership = var.object_ownership  # "BucketOwnerEnforced" disables ACLs
  }
}

# Optional Bucket ACL (only when not BucketOwnerEnforced)
resource "aws_s3_bucket_acl" "this" {
  count  = var.object_ownership == "BucketOwnerPreferred" || var.object_ownership == "ObjectWriter" ? 1 : 0
  bucket = aws_s3_bucket.this.id
  acl    = var.bucket_acl   # e.g., "private", "public-read"
}

# Block Public Access (bucket-level)
resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = var.block_public_acls
  block_public_policy     = var.block_public_policy
  ignore_public_acls      = var.ignore_public_acls
  restrict_public_buckets = var.restrict_public_buckets
}

# Block Public Access (account-level)
resource "aws_s3_account_public_access_block" "account" {
  count                   = var.enable_account_level_pab ? 1 : 0
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Versioning
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

# Default bucket encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_key_arn == null ? "AES256" : "aws:kms"
      kms_master_key_id = var.kms_key_arn
    }
    bucket_key_enabled = var.bucket_key_enabled
  }
}

# Access logging (to dedicated logs bucket or an existing one)
resource "aws_s3_bucket" "logs" {
  count         = var.enable_access_logging && var.create_logs_bucket ? 1 : 0
  bucket        = var.logs_bucket_name
  force_destroy = true
  tags          = merge(var.tags, { Purpose = "access-logs" })
}
resource "aws_s3_bucket_ownership_controls" "logs" {
  count  = var.enable_access_logging && var.create_logs_bucket ? 1 : 0
  bucket = aws_s3_bucket.logs[0].id
  rule { object_ownership = "BucketOwnerEnforced" }
}
resource "aws_s3_bucket_public_access_block" "logs" {
  count                   = var.enable_access_logging && var.create_logs_bucket ? 1 : 0
  bucket                  = aws_s3_bucket.logs[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
resource "aws_s3_bucket_logging" "this" {
  count  = var.enable_access_logging ? 1 : 0
  bucket = aws_s3_bucket.this.id
  target_bucket = var.create_logs_bucket ? aws_s3_bucket.logs[0].id : var.logs_bucket_name
  target_prefix = var.logs_prefix
}

# Website hosting / Redirect
resource "aws_s3_bucket_website_configuration" "this" {
  count  = var.enable_website ? 1 : 0
  bucket = aws_s3_bucket.this.id

  dynamic "index_document" {
    for_each = var.website_redirect_host == null ? [1] : []
    content { suffix = var.website_index_document }
  }
  dynamic "error_document" {
    for_each = var.website_error_document != null && var.website_redirect_host == null ? [1] : []
    content { key = var.website_error_document }
  }
  dynamic "redirect_all_requests_to" {
    for_each = var.website_redirect_host != null ? [1] : []
    content {
      host_name = var.website_redirect_host
      protocol  = var.website_redirect_protocol
    }
  }
}

# (Optional) Public-read policy for website
data "aws_iam_policy_document" "website_public" {
  count = var.enable_website && var.website_make_public ? 1 : 0
  statement {
    sid     = "AllowPublicReadForWebsite"
    effect  = "Allow"
    actions = ["s3:GetObject"]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    resources = ["${aws_s3_bucket.this.arn}/*"]
  }
}
resource "aws_s3_bucket_policy" "website_public" {
  count  = var.enable_website && var.website_make_public ? 1 : 0
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.website_public[0].json
}

# Notifications (SNS/SQS/Lambda)
resource "aws_s3_bucket_notification" "this" {
  count  = (length(var.sns_topic_arns) + length(var.sqs_queue_arns) + length(var.lambda_function_arns)) > 0 ? 1 : 0
  bucket = aws_s3_bucket.this.id

  dynamic "topic" {
    for_each = var.sns_topic_arns
    content {
      topic_arn     = topic.value
      events        = var.notification_events
      filter_prefix = var.notification_prefix
      filter_suffix = var.notification_suffix
    }
  }

  dynamic "queue" {
    for_each = var.sqs_queue_arns
    content {
      queue_arn     = queue.value
      events        = var.notification_events
      filter_prefix = var.notification_prefix
      filter_suffix = var.notification_suffix
    }
  }

  dynamic "lambda_function" {
    for_each = var.lambda_function_arns
    content {
      lambda_function_arn = lambda_function.value
      events              = var.notification_events
      filter_prefix       = var.notification_prefix
      filter_suffix       = var.notification_suffix
    }
  }
}

# Lifecycle policies (transition/expiration)
resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count  = length(var.lifecycle_rules) > 0 ? 1 : 0
  bucket = aws_s3_bucket.this.id

  dynamic "rule" {
    for_each = var.lifecycle_rules
    content {
      id     = rule.value.id
      status = rule.value.enabled ? "Enabled" : "Disabled"

      dynamic "filter" {
        for_each = [1]
        content { prefix = lookup(rule.value, "prefix", null) }
      }

      dynamic "transition" {
        for_each = lookup(rule.value, "transitions", [])
        content {
          days          = transition.value.days
          storage_class = transition.value.storage_class
        }
      }

      dynamic "noncurrent_version_transition" {
        for_each = lookup(rule.value, "noncurrent_transitions", [])
        content {
          noncurrent_days = noncurrent_version_transition.value.days
          storage_class   = noncurrent_version_transition.value.storage_class
        }
      }

      noncurrent_version_expiration {
        noncurrent_days = lookup(rule.value, "noncurrent_expiration_days", null)
      }

      dynamic "expiration" {
        for_each = [lookup(rule.value, "expiration_days", null)]
        content { days = expiration.value }
      }
    }
  }
}

# S3 Transfer Acceleration
resource "aws_s3_bucket_accelerate_configuration" "this" {
  bucket = aws_s3_bucket.this.id
  status = var.enable_transfer_acceleration ? "Enabled" : "Suspended"
}

# Storage Class Analysis (per-prefix analytics)
resource "aws_s3_bucket_analytics_configuration" "sca" {
  count  = length(var.analytics_configs) > 0 ? length(var.analytics_configs) : 0
  bucket = aws_s3_bucket.this.id
  name   = var.analytics_configs[count.index].name
  filter {
    prefix = try(var.analytics_configs[count.index].prefix, null)
    tags   = try(var.analytics_configs[count.index].tags, null)
  }
  storage_class_analysis {
    data_export {
      output_schema_version = "V_1"
      destination {
        s3_bucket_destination {
          format          = "CSV"
          bucket_arn      = var.analytics_configs[count.index].destination_bucket_arn
          prefix          = try(var.analytics_configs[count.index].destination_prefix, null)
        }
      }
    }
  }
}

# Bucket Policy (attach arbitrary JSON)
resource "aws_s3_bucket_policy" "extra" {
  count  = var.bucket_policy_json != null ? 1 : 0
  bucket = aws_s3_bucket.this.id
  policy = var.bucket_policy_json
}


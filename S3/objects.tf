# "Creating a Folder" in S3 == create a zero-byte key with a trailing slash
resource "aws_s3_object" "folders" {
  for_each = toset(var.create_folders)     # e.g., ["incoming/", "archive/2025/"]
  bucket   = aws_s3_bucket.this.id
  key      = each.value
  content  = ""                            # zero-byte
}

# Upload a whole local directory (files only) to a prefix
# Example: set var.upload_local_dir = "./site" and var.upload_prefix = "web/"
locals {
  discovered_files = var.upload_local_dir == null ? [] : fileset(var.upload_local_dir, var.upload_glob)
  effective_files  = length(var.upload_files) > 0 ? var.upload_files : local.discovered_files
}

resource "aws_s3_object" "uploaded" {
  for_each = { for f in local.effective_files : f => f }

  bucket = aws_s3_bucket.this.id
  key    = "${var.upload_prefix}${each.key}"
  source = "${var.upload_local_dir}/${each.key}"
  etag   = filemd5("${var.upload_local_dir}/${each.key}")

  # Per-object encryption/tags/metadata
  server_side_encryption = var.object_sse_kms_key_arn == null && var.object_sse == "aws:kms" ? null : var.object_sse
  kms_key_id             = var.object_sse == "aws:kms" ? var.object_sse_kms_key_arn : null
  storage_class          = var.object_storage_class
  content_type           = lookup(var.object_metadata, "content-type", null)
  metadata               = var.object_metadata
  tags                   = var.object_tags

  # Object Lock (requires bucket Object Lock + versioning enabled)
  object_lock_mode                = var.object_lock_mode        # "GOVERNANCE" or "COMPLIANCE"
  object_lock_retain_until_date   = var.object_lock_retain_until_date
  object_lock_legal_hold_status   = var.object_lock_legal_hold_status  # "ON"/"OFF"
}


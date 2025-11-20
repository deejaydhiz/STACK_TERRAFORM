############################################
# Folders & Uploads (S3 object management) #
############################################

# ---- Folder placeholders (zero-byte objects) ----
resource "aws_s3_object" "folders" {
  for_each = toset(var.create_folders)
  bucket   = aws_s3_bucket.this.id
  key      = each.value
  content  = "" # creates a zero-byte key
  tags     = var.object_tags
  metadata = var.object_metadata
}

# ---- Discover files to upload ----
locals {
  # Files discovered from glob
  discovered_files = var.upload_local_dir == null ? [] : fileset(var.upload_local_dir, var.upload_glob)

  # If explicit list provided, prefer that; else the discovered list
  effective_files = length(var.upload_files) > 0 ? var.upload_files : local.discovered_files

  # Minimal MIME type map (extend as needed)
  mime_map = {
    ".html" = "text/html"
    ".htm"  = "text/html"
    ".css"  = "text/css"
    ".js"   = "application/javascript"
    ".json" = "application/json"
    ".png"  = "image/png"
    ".jpg"  = "image/jpeg"
    ".jpeg" = "image/jpeg"
    ".gif"  = "image/gif"
    ".svg"  = "image/svg+xml"
    ".txt"  = "text/plain"
    ".xml"  = "application/xml"
    ".pdf"  = "application/pdf"
  }
}

# Helper to extract file extension
# regex("\\.[^.]+$", each.key) -> ".ext" or error -> ""
# lookup(...) returns null if extension not in map (S3/Browser guesses)
resource "aws_s3_object" "uploaded" {
  for_each = { for f in local.effective_files : f => f }
  acl      = "public-read"
  bucket   = aws_s3_bucket.this.id
  key      = "${var.upload_prefix}${each.key}"
  source   = "${var.upload_local_dir}/${each.key}"
  etag     = filemd5("${var.upload_local_dir}/${each.key}")

  content_type = lookup(local.mime_map, try(regex("\\.[^.]+$", each.key), ""), null)

  server_side_encryption = var.object_sse
  kms_key_id             = var.object_sse == "aws:kms" ? var.object_sse_kms_key_arn : null

  tags     = var.object_tags
  metadata = var.object_metadata

  # Optional: ensure bucket is made before objects (usually implied)
  depends_on = [aws_s3_bucket.this]
}

############################
# Optional CLI-based help  #
############################

# List all objects
resource "null_resource" "list_objects" {
  count = var.enable_helpers ? 1 : 0
  provisioner "local-exec" {
    command = "aws s3 ls s3://${aws_s3_bucket.this.bucket} --recursive"
  }
  triggers = { bucket = aws_s3_bucket.this.bucket }
}

# Download an object
resource "null_resource" "download_object" {
  count = var.enable_helpers && var.download_object_key != null && var.download_local_path != null ? 1 : 0
  provisioner "local-exec" {
    command = "aws s3 cp s3://${aws_s3_bucket.this.bucket}/${var.download_object_key} ${var.download_local_path}"
  }
  triggers = {
    bucket = aws_s3_bucket.this.bucket
    key    = var.download_object_key
    path   = var.download_local_path
  }
}

# Undelete a versioned object by removing the delete marker
resource "null_resource" "undelete_object" {
  count = var.enable_helpers && var.undelete_object_key != null && var.undelete_delete_marker_version_id != null ? 1 : 0
  provisioner "local-exec" {
    command = "aws s3api delete-object --bucket ${aws_s3_bucket.this.bucket} --key ${var.undelete_object_key} --version-id ${var.undelete_delete_marker_version_id}"
  }
  triggers = {
    bucket     = aws_s3_bucket.this.bucket
    key        = var.undelete_object_key
    version_id = var.undelete_delete_marker_version_id
  }
}

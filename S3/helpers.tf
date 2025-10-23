# These "procedural" actions are best done with AWS CLI. 
# You can run them on demand with 'terraform apply -target=...'

# List objects
resource "null_resource" "list_objects" {
  count = var.enable_cli_helpers ? 1 : 0
  provisioner "local-exec" {
    command = "aws s3 ls s3://${aws_s3_bucket.this.bucket} --recursive"
  }
  triggers = { bucket = aws_s3_bucket.this.bucket }
}

# Download an object
resource "null_resource" "download_object" {
  count = var.enable_cli_helpers && var.download_object_key != null ? 1 : 0
  provisioner "local-exec" {
    command = "aws s3 cp s3://${aws_s3_bucket.this.bucket}/${var.download_object_key} ${var.download_local_path}"
  }
  triggers = {
    key   = var.download_object_key
    path  = var.download_local_path
    buck  = aws_s3_bucket.this.bucket
  }
}

# Undelete (remove a delete marker) – requires versioning
resource "null_resource" "undelete_object" {
  count = var.enable_cli_helpers && var.undelete_object_key != null && var.undelete_delete_marker_version_id != null ? 1 : 0
  provisioner "local-exec" {
    command = "aws s3api delete-object --bucket ${aws_s3_bucket.this.bucket} --key ${var.undelete_object_key} --version-id ${var.undelete_delete_marker_version_id}"
  }
  triggers = {
    key        = var.undelete_object_key
    version_id = var.undelete_delete_marker_version_id
  }
}

# Restore from Glacier (Standard retrieval by default)
resource "null_resource" "restore_glacier" {
  count = var.enable_cli_helpers && var.restore_object_key != null ? 1 : 0
  provisioner "local-exec" {
    command = "aws s3api restore-object --bucket ${aws_s3_bucket.this.bucket} --key ${var.restore_object_key} --restore-request '{\"Days\": ${var.restore_days}, \"GlacierJobParameters\": {\"Tier\": \"${var.restore_tier}\"}}'"
  }
  triggers = {
    key   = var.restore_object_key
    days  = tostring(var.restore_days)
    tier  = var.restore_tier
  }
}

# Empty bucket quickly
resource "null_resource" "empty_bucket" {
  count = var.enable_cli_helpers && var.enable_empty_bucket ? 1 : 0
  provisioner "local-exec" {
    command = "aws s3 rm s3://${aws_s3_bucket.this.bucket} --recursive"
  }
  triggers = { run = timestamp() }
}

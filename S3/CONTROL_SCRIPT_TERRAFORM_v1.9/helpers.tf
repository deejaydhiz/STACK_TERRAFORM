#####################################
# Story 3: Versioning & Recovery    #
#####################################
# 2) Helper: list versions under an optional prefix
# Run with: terraform apply -target=null_resource.list_versions
resource "null_resource" "list_versions" {
  # always available; runs only when targeted
  provisioner "local-exec" {
    command = "aws s3api list-object-versions --bucket ${aws_s3_bucket.this.bucket}"
  }
  triggers = {
    bucket = aws_s3_bucket.this.bucket
    prefix = var.recovery_prefix
  }
}

# 3) Helper: UNDELETE by removing the delete marker version
# Usage:
#   - set recover_object_key = "path/to/file"
#   - set recover_version_id to the delete-marker's VersionId
#   - terraform apply -target=null_resource.remove_delete_marker
resource "null_resource" "remove_delete_marker" {
  count = var.recover_object_key != null && var.recover_version_id != null ? 1 : 0
  provisioner "local-exec" {
    command = "aws s3api delete-object --bucket ${aws_s3_bucket.this.bucket} --key ${var.recover_object_key} --version-id ${var.recover_version_id}"
  }
  triggers = {
    bucket     = aws_s3_bucket.this.bucket
    key        = var.recover_object_key
    version_id = var.recover_version_id
  }
}

# 4) Helper: RESTORE a previous version to be the current version
# This copies a specific version over the same key (server-side copy).
# Usage:
#   - Set recover_object_key and recover_version_id (a non-delete-marker version)
#   - terraform apply -target=null_resource.restore_version
resource "null_resource" "restore_version" {
  count = var.recover_object_key != null && var.recover_version_id != null ? 1 : 0
  provisioner "local-exec" {
    command = "aws s3api copy-object --bucket ${aws_s3_bucket.this.bucket} --copy-source ${aws_s3_bucket.this.bucket}/${var.recover_object_key}?versionId=${var.recover_version_id} --key ${var.recover_object_key}"
  }
  triggers = {
    bucket     = aws_s3_bucket.this.bucket
    key        = var.recover_object_key
    version_id = var.recover_version_id
  }
}

# 5) Helper: Glacier/Deep Archive RESTORE (if the object is archived)
# Usage:
#   - set recover_object_key to the archived key
#   - optional: set recover_version_id to restore a specific version
#   - terraform apply -target=null_resource.glacier_restore
resource "null_resource" "glacier_restore" {
  count = var.recover_object_key != null ? 1 : 0
  provisioner "local-exec" {
    command = "aws s3api restore-object --bucket ${aws_s3_bucket.this.bucket} --key ${var.recover_object_key} ${var.recover_version_id} --restore-request '{\"Days\": ${var.restore_days}, \"GlacierJobParameters\": {\"Tier\": \"${var.restore_tier}\"}}'"
  }
  triggers = {
    bucket     = aws_s3_bucket.this.bucket
    key        = var.recover_object_key
    version_id = var.recover_version_id != null ? var.recover_version_id : ""
    days       = tostring(var.restore_days)
    tier       = var.restore_tier
  }
}
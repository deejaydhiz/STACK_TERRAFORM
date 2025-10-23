# Destination bucket for CRR (optional: create or use existing)
resource "aws_s3_bucket" "dest" {
  count         = var.enable_crr && var.create_dest_bucket ? 1 : 0
  bucket        = var.dest_bucket_name
  force_destroy = true
  tags          = merge(var.tags, { Purpose = "crr-destination" })
}
# enable versioning on the destination bucket
resource "aws_s3_bucket_versioning" "dest" {
  count  = var.enable_crr ? 1 : 0
  bucket = var.dest_bucket_name
  versioning_configuration {
    status = "Enabled"
  }
}

# IAM role for replication
data "aws_iam_policy_document" "replication_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "replication" {
  count              = var.enable_crr ? 1 : 0
  name               = "${var.bucket_name}-crr-role"
  assume_role_policy = data.aws_iam_policy_document.replication_trust.json
  tags               = var.tags
}

# Policy allowing S3 to replicate objects
data "aws_iam_policy_document" "replication_policy" {
  count = var.enable_crr ? 1 : 0
  statement {
    sid     = "ReplicationObject"
    effect  = "Allow"
    actions = ["s3:GetReplicationConfiguration", "s3:ListBucket"]
    resources = [aws_s3_bucket.this.arn]
  }
  statement {
    sid     = "ReadSource"
    effect  = "Allow"
    actions = ["s3:GetObjectVersion", "s3:GetObjectVersionAcl", "s3:GetObjectVersionTagging"]
    resources = ["${aws_s3_bucket.this.arn}/*"]
  }
  statement {
    sid     = "WriteDestination"
    effect  = "Allow"
    actions = ["s3:ReplicateObject", "s3:ReplicateDelete", "s3:ReplicateTags", "s3:ObjectOwnerOverrideToBucketOwner"]
    resources = ["${(var.create_dest_bucket ? aws_s3_bucket.dest[0].arn : "arn:aws:s3:::${var.dest_bucket_name}")}/*"]
  }
}

resource "aws_iam_role_policy" "replication" {
  count  = var.enable_crr ? 1 : 0
  name   = "${var.bucket_name}-crr-policy"
  role   = aws_iam_role.replication[0].id
  policy = data.aws_iam_policy_document.replication_policy[0].json
}

# Replication rules
resource "aws_s3_bucket_replication_configuration" "this" {
  count  = var.enable_crr ? 1 : 0
  bucket = aws_s3_bucket.this.id
  role   = aws_iam_role.replication[0].arn

  dynamic "rule" {
    for_each = var.crr_rules
    content {
      id       = rule.value.id
      status   = rule.value.enabled ? "Enabled" : "Disabled"
      priority = rule.value.priority

      filter {
        prefix = lookup(rule.value, "prefix", null)
        # (add tags[] here if you need tag-based filtering)
      }

      delete_marker_replication { status = "Enabled" }

      destination {
        bucket        = var.create_dest_bucket ? aws_s3_bucket.dest[0].arn : "arn:aws:s3:::${var.dest_bucket_name}"
        storage_class = lookup(rule.value, "storage_class", null)
        account       = null
        # Change ownership to destination bucket owner if needed:
        access_control_translation { owner = "Destination" }
        #encryption_configuration { replica_kms_key_id = var.replica_kms_key_arn }
      }
    }
  }

  depends_on = [aws_iam_role_policy.replication]
}

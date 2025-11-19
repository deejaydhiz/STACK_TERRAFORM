terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 5.50.0" }
  }
}

# Create the bucket
resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name
  region = var.bucket_region
  force_destroy = var.force_destroy   # allows emptying/deleting via destroy
  tags   = var.tags
}

# Ownership controls (recommended; Enforced disables ACLs)
resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id
  rule {
    object_ownership = var.object_ownership
  }
}

# Public Access Block (secure defaults)
resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = var.public_access_block.block_public_acls
  ignore_public_acls      = var.public_access_block.ignore_public_acls
  block_public_policy     = var.public_access_block.block_public_policy
  restrict_public_buckets = var.public_access_block.restrict_public_buckets
}

# Default encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.default_encryption
      kms_master_key_id = var.default_encryption == "aws:kms" ? var.kms_key_arn : null
    }
  }
  depends_on = [aws_s3_bucket_public_access_block.this]
}

# Versioning (optional)
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

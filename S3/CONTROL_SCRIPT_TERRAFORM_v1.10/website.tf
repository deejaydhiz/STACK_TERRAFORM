#####################################
# Story 8: Website Hosting & Redirect
#####################################

resource "aws_s3_bucket_website_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }

  routing_rule {
    condition {
      key_prefix_equals = "docs/"
    }
    redirect {
      replace_key_prefix_with = "documents/"
    }
  }

  depends_on = [aws_s3_bucket_public_access_block.this]
}

# Enable public read access for website hosting
data "aws_iam_policy_document" "website_public" {
  count = var.enable_website && var.enable_website_public_read ? 1 : 0

  statement {
    sid    = "PublicReadForWebsite"
    effect = "Allow"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.this.arn}/*"]
  }
}

resource "aws_s3_bucket_policy" "website_public" {
  count      = var.enable_website && var.enable_website_public_read ? 1 : 0
  bucket     = aws_s3_bucket.this.id
  policy     = data.aws_iam_policy_document.website_public[0].json
  depends_on = [aws_s3_bucket_website_configuration.this]
}

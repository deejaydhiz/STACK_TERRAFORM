resource "aws_kms_key" "s3" {
  count                   = var.create_kms_key ? 1 : 0
  description             = "CMK for S3 default encryption"
  enable_key_rotation     = true
  deletion_window_in_days = 30

  policy = jsonencode({
    Version : "2012-10-17",
    Statement : concat(
      [
        # Allow root of the account full admin
        {
          Sid : "EnableRootAdmin",
          Effect : "Allow",
          Principal : { AWS : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" },
          Action : "kms:*",
          Resource : "*"
        }
      ],
      length(var.kms_key_admin_arns) > 0 ? [
        {
          Sid : "AllowKeyAdmins",
          Effect : "Allow",
          Principal : { AWS : var.kms_key_admin_arns },
          Action : [
            "kms:Create*", "kms:Describe*", "kms:Enable*", "kms:List*", "kms:Put*",
            "kms:Update*", "kms:Revoke*", "kms:Disable*", "kms:Get*", "kms:Delete*",
            "kms:ScheduleKeyDeletion", "kms:CancelKeyDeletion", "kms:TagResource", "kms:UntagResource"
          ],
          Resource : "*"
        }
      ] : [],
      length(var.kms_key_user_arns) > 0 ? [
        {
          Sid : "AllowKeyUsage",
          Effect : "Allow",
          Principal : { AWS : var.kms_key_user_arns },
          Action : [
            "kms:Encrypt", "kms:Decrypt", "kms:ReEncrypt*", "kms:GenerateDataKey*", "kms:DescribeKey"
          ],
          Resource : "*"
        }
      ] : []
    )
  })
}

resource "aws_kms_alias" "s3" {
  count         = var.create_kms_key ? 1 : 0
  name          = var.kms_key_alias
  target_key_id = aws_kms_key.s3[0].key_id
}


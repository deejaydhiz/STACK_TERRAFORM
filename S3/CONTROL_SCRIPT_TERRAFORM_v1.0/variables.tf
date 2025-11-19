# AWS S3 Bucket Module - Variables
variable "bucket_region" {
  type    = string
  default = "us-east-1"
}

variable "bucket_name" {
  description = "S3 bucket name (must be globally unique)"
  type        = string
}

variable "force_destroy" {
  description = "Allow bucket to be destroyed even if it contains objects"
  type        = bool
  default     = false
}

variable "enable_versioning" {
  description = "Enable S3 versioning"
  type        = bool
  default     = true
}

variable "default_encryption" {
  description = "Default encryption mode: AES256 or aws:kms"
  type        = string
  default     = "AES256"
  validation {
    condition     = contains(["AES256", "aws:kms"], var.default_encryption)
    error_message = "default_encryption must be AES256 or aws:kms."
  }
}

variable "kms_key_arn" {
  description = "KMS key ARN for SSE-KMS (required if default_encryption=aws:kms)"
  type        = string
  default     = null
}

variable "object_ownership" {
  description = "S3 object ownership control"
  type        = string
  default     = "BucketOwnerEnforced" # modern default; disables ACLs
  validation {
    condition     = contains(["BucketOwnerEnforced","BucketOwnerPreferred","ObjectWriter"], var.object_ownership)
    error_message = "object_ownership must be one of BucketOwnerEnforced, BucketOwnerPreferred, ObjectWriter."
  }
}

variable "public_access_block" {
  description = "Bucket-level Public Access Block settings"
  type = object({
    block_public_acls       : bool
    ignore_public_acls      : bool
    block_public_policy     : bool
    restrict_public_buckets : bool
  })
  default = {
    block_public_acls       = true
    ignore_public_acls      = true
    block_public_policy     = true
    restrict_public_buckets = true
  }
}

variable "tags" {
  description = "Common tags for the bucket"
  type        = map(string)
  default     = {}
}


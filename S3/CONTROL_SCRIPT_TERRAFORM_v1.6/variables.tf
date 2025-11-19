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
    condition     = contains(["BucketOwnerEnforced", "BucketOwnerPreferred", "ObjectWriter"], var.object_ownership)
    error_message = "object_ownership must be one of BucketOwnerEnforced, BucketOwnerPreferred, ObjectWriter."
  }
}

variable "public_access_block" {
  description = "Bucket-level Public Access Block settings"
  type = object({
    block_public_acls : bool
    ignore_public_acls : bool
    block_public_policy : bool
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

# Folder & Objects Management variables
variable "create_folders" {
  description = "List of logical folders to create (must end with /)"
  type        = list(string)
  default     = []
}

variable "upload_local_dir" {
  description = "Local base directory to upload files from (relative or absolute). Example: ./site"
  type        = string
  default     = null
}

variable "upload_glob" {
  description = "Glob pattern under upload_local_dir (e.g., **, *.html, assets/**)"
  type        = string
  default     = "**"
}

variable "upload_files" {
  description = "Optional explicit list of file paths (relative to upload_local_dir). If set, overrides upload_glob."
  type        = list(string)
  default     = []
}

variable "upload_prefix" {
  description = "S3 key prefix (folder) to place uploaded files under. Example: web/"
  type        = string
  default     = ""
}

variable "object_tags" {
  description = "Tags to apply to uploaded objects"
  type        = map(string)
  default     = {}
}

variable "object_metadata" {
  description = "Metadata to apply to uploaded objects"
  type        = map(string)
  default     = {}
}

variable "object_sse" {
  description = "Server-side encryption for uploaded objects: AES256 or aws:kms"
  type        = string
  default     = "AES256"
  validation {
    condition     = contains(["AES256", "aws:kms"], var.object_sse)
    error_message = "object_sse must be AES256 or aws:kms."
  }
}

variable "object_sse_kms_key_arn" {
  description = "KMS key ARN when object_sse=aws:kms"
  type        = string
  default     = null
}

variable "enable_helpers" {
  description = "Enable CLI-based helpers (list/download/undelete). Use with -target when running."
  type        = bool
  default     = true
}

variable "download_object_key" {
  description = "Object key to download (for helper)"
  type        = string
  default     = null
}

variable "download_local_path" {
  description = "Local path to save downloaded object (for helper)"
  type        = string
  default     = null
}

variable "undelete_object_key" {
  description = "Object key whose delete marker you want to remove (for helper)"
  type        = string
  default     = null
}

variable "undelete_delete_marker_version_id" {
  description = "Version ID of the delete marker to remove (for helper)"
  type        = string
  default     = null
}

# Helpers for recovery actions
variable "recovery_prefix" {
  description = "Prefix to limit version listings/restores (optional)"
  type        = string
  default     = ""
}

variable "recover_object_key" {
  description = "Object key to operate on (for undelete/restore)"
  type        = string
  default     = null
}

variable "recover_version_id" {
  description = "Specific version ID to restore or delete (when needed)"
  type        = string
  default     = null
}

variable "restore_days" {
  description = "Glacier restore: number of days to keep temporary restored copy"
  type        = number
  default     = 7
}

variable "restore_tier" {
  description = "Glacier restore tier: Bulk | Standard | Expedited"
  type        = string
  default     = "Standard"
}

# Encryption and Security
variable "create_kms_key" {
  description = "Create a new KMS CMK for the bucket"
  type        = bool
  default     = false
}

variable "kms_key_alias" {
  description = "Alias for the CMK if created"
  type        = string
  default     = "alias/s3-default-encryption"
}

variable "kms_key_admin_arns" {
  description = "Principals who can administer the CMK"
  type        = list(string)
  default     = []
}

variable "kms_key_user_arns" {
  description = "Principals (apps/roles) allowed to encrypt/decrypt with CMK"
  type        = list(string)
  default     = []
}

variable "enforce_tls" {
  description = "Deny non-TLS requests via bucket policy"
  type        = bool
  default     = true
}

variable "enforce_encryption" {
  description = "Deny unencrypted uploads via bucket policy"
  type        = bool
  default     = true
}

variable "enforce_kms_key" {
  description = "When true, only allow PUT with the chosen KMS key"
  type        = bool
  default     = false
}

# Logging Variables
# ---- CloudTrail Data Events ----
variable "enable_cloudtrail_data_events" {
  description = "Enable CloudTrail data events for this bucket"
  type        = bool
  default     = false
}

variable "cloudtrail_trail_name" {
  description = "Name of the (new) CloudTrail trail to create for S3 data events"
  type        = string
  default     = "s3-data-events-trail"
}

variable "cloudtrail_log_bucket_name" {
  description = "S3 bucket name where CloudTrail writes logs"
  type        = string
  default     = null # if null, one will be created: <trail_name>-logs-<account>
}

# ---- S3 Server Access Logging (classic) ----
variable "enable_server_access_logging" {
  description = "Enable S3 server access logging from the source bucket"
  type        = bool
  default     = false
}

variable "logs_bucket_name" {
  description = "Destination bucket for access logs (must allow Log Delivery writes)"
  type        = string
  default     = null # if null, create one when enable_server_access_logging = true
}

variable "logs_prefix" {
  description = "Prefix (folder) in the log bucket for delivered logs"
  type        = string
  default     = "s3-logs/"
}

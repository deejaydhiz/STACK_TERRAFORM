# AWS S3 Bucket Module - Variables
variable "region" {
  type    = string
  default = "us-east-1"
}
variable "bucket_name" {
  type = string
}
variable "bucket_id" {
  type = string
}
variable "force_destroy" {
  type    = bool
  default = false
}
variable "tags" {
  type    = map(string)
  default = {}
}

# Ownership / ACLs
variable "object_ownership" {
  type    = string
  default = "BucketOwnerEnforced"
} # or "BucketOwnerPreferred", "ObjectWriter"
variable "bucket_acl" {
  type    = string
  default = "private"
}

# Public access block (bucket)
variable "block_public_acls" {
  type    = bool
  default = true
}
variable "block_public_policy" {
  type    = bool
  default = true
}
variable "ignore_public_acls" {
  type    = bool
  default = true
}
variable "restrict_public_buckets" {
  type    = bool
  default = true
}
# Public access block (account)
variable "enable_account_level_pab" {
  type    = bool
  default = false
}

# Versioning & encryption
variable "enable_versioning" {
  type    = bool
  default = true
}
variable "kms_key_arn" {
  type    = string
  default = null
}
variable "bucket_key_enabled" {
  type    = bool
  default = true
}

# Object Lock
variable "enable_object_lock" {
  type    = bool
  default = false
}
variable "object_lock_mode" {
  type    = string
  default = null
}  # "GOVERNANCE" | "COMPLIANCE"
variable "object_lock_retain_until_date" {
  type    = string
  default = null
} # ISO8601 date
variable "object_lock_legal_hold_status" {
  type    = string
  default = null
} # "ON" | "OFF"

# Access logging
variable "enable_access_logging" {
  type    = bool
  default = false
}
variable "create_logs_bucket" {
  type    = bool
  default = true
}
variable "logs_bucket_name" {
  type    = string
  default = null
}
variable "logs_prefix" {
  type    = string
  default = "s3-access-logs/"
}

# Website / redirect
variable "enable_website" {
  type    = bool
  default = false
}
variable "website_index_document" {
  type    = string
  default = "index.html"
}
variable "website_error_document" {
  type    = string
  default = null
}
variable "website_make_public" {
  type    = bool
  default = false
}
variable "website_redirect_host" {
  type    = string
  default = null
}
variable "website_redirect_protocol" {
  type    = string
  default = "https"
}

# Notifications
variable "sns_topic_arns" {
  type    = list(string)
  default = []
}
variable "sqs_queue_arns" {
  type    = list(string)
  default = []
}
variable "lambda_function_arns" {
  type    = list(string)
  default = []
}
variable "notification_events" {
  type    = list(string)
  default = ["s3:ObjectCreated:*"]
}
variable "notification_prefix" {
  type    = string
  default = null
}
variable "notification_suffix" {
  type    = string
  default = null
}

# Lifecycle
variable "lifecycle_rules" {
  type = list(object({
    id                          = string
    enabled                     = bool
    prefix                      = optional(string)
    transitions                 = optional(list(object({ days = number, storage_class = string })), [])
    noncurrent_transitions      = optional(list(object({ days = number, storage_class = string })), [])
    expiration_days             = optional(number)
    noncurrent_expiration_days  = optional(number)
  }))
  default = []
}

# Storage Class Analysis
variable "analytics_configs" {
  description = "Per-prefix Storage Class Analysis configs"
  type = list(object({
    name                   = string
    prefix                 = optional(string)
    tags                   = optional(map(string))
    destination_bucket_arn = string                 # REQUIRED
    destination_prefix     = optional(string)       # default: "analytics/"
    destination_format     = optional(string)       # "CSV" (only supported value today)
    output_schema_version  = optional(string)       # "V_1"
  }))
  default = []
}

# Add a raw bucket policy JSON (string)
variable "bucket_policy_json" {
  type    = string
  default = null
}

# Object upload & per-object settings
variable "create_folders" {
  type    = list(string)
  default = []
} # e.g., ["incoming/", "archive/"]
variable "upload_local_dir" {
  type    = string
  default = null
}     # local path to directory
variable "upload_files" {
  description = "Optional explicit list of relative file paths (under upload_local_dir) to upload. If set, overrides upload_glob."
  type        = list(string)
  default     = []
}
variable "upload_glob" {
  type    = string
  default = "**"
}     # which files inside local dir
variable "upload_prefix" {
  type    = string
  default = ""
}       # destination prefix in bucket

variable "object_sse" {
  type    = string
  default = null
}     # "AES256" | "aws:kms"
variable "object_sse_kms_key_arn" {
  type    = string
  default = null
}
variable "object_storage_class" {
  type    = string
  default = null
}     # e.g., "STANDARD_IA"
variable "object_tags" {
  type    = map(string)
  default = {}
}  # Add tags to an S3 object
variable "object_metadata" {
  type    = map(string)
  default = {}
}  # Add metadata to an S3 object

# CRR / replication
variable "enable_crr" {
  type    = bool
  default = false
}
variable "create_dest_bucket" {
  type    = bool
  default = true
}
variable "dest_bucket_name" {
  type    = string
  default = null
}
variable "replica_kms_key_arn" {
  type    = string
  default = null
}
variable "crr_rules" {
  type = list(object({
    id            = string
    enabled       = bool
    priority      = number
    prefix        = optional(string)
    storage_class = optional(string)
  }))
  default = []
}

# CloudTrail data events for S3 objects
variable "enable_cloudtrail_data_events" {
  type    = bool
  default = false
}

# Transfer Acceleration
variable "enable_transfer_acceleration" {
  type    = bool
  default = false
}

# CLI helpers (list/download/undelete/restore/empty)
variable "enable_cli_helpers" {
  type    = bool
  default = true
}
variable "download_object_key" {
  type    = string
  default = null
}
variable "download_local_path" {
  type    = string
  default = "./download.bin"
}
variable "undelete_object_key" {
  type    = string
  default = null
}
variable "undelete_delete_marker_version_id" {
  type    = string
  default = null
}
variable "restore_object_key" {
  type    = string
  default = null
}
variable "restore_days" {
  type    = number
  default = 7
}
variable "restore_tier" {
  type    = string
  default = "Standard"
} # "Bulk" | "Standard" | "Expedited"
variable "enable_empty_bucket" {
  type    = bool
  default = false
}

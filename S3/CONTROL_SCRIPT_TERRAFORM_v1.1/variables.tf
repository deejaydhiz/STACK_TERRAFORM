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

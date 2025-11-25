variable "aws_region" {
  description = "This is the AWS region to build the resources"
  type = string
  default = "us-east-1"
}

variable "env" {
  description = "The environment to deploy to"
  type        = string
  default     = "dev"
}

variable "accounts" {
  description = "Mapping of environment names to AWS account IDs"
  type        = map(string)
  default = {
    dev  = "186769093804"
    prod = "807867956627"
  }
}
variable "db_name" {
  description = "The name of the database to create"
  type        = string
  default     = "blog_db"
}

variable "db_username" {
  description = "The master username at time of database creation"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "The master password for the database"
  type        = string
  sensitive   = true
}


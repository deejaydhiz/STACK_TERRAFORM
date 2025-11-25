variable "aws_region" {
  description = "This is the AWS region to build the resources"
  type = string
  default = "us-east-1"
}

variable "env" {
  description = "The environment for the deployment"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "test", "uat", "prod"], var.env)
    error_message = "The env variable must be one of the following: dev, test, uat, prod."
  }
}

variable "accounts" {
  description = "Mapping of environment names to AWS account IDs"
  type        = map(string)
  default = {
    dev  = "186769093804"
    prod = "807867956627"
  }
}

variable "tags" {
  description = "A map of tags to assign to resources"
  type        = map(string)
  default = {
    stackTeam   = "stackcloud14"
    OwnerEmail  = "stackawsdeij@gmail.com"
    Environment = "dev"
    Project     = "blog-deployment"
    CostCenter  = "cc1234"
    Application = "blog-website"
  }
}

variable "vpc_id" {
  description = "The VPC ID where resources will be deployed"
  type        = string
  default     = ""
}

variable "sg_name" {
  description = "The name of the security group for the blog deployment"
  type        = string
  default     = "blog_SG"
}

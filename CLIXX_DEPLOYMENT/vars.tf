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
    type = map(string)
    default = {
        dev     = "186769093804"
        uat     = "961424819918"
    }
}

variable "vpc_id" {
  description = "The VPC ID where resources will be deployed"
  type        = string
  default     = "vpc-05b6bd3414e30ee87"
} 
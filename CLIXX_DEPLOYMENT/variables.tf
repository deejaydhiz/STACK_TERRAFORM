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

variable "db_password" {
  description = "The password for the database"
  type        = string
  sensitive   = true
}

variable "rds_instance_properties" {
  description = "A map of RDS instance properties"
  type        = map(string)
  default = {
    identifier          = "clixx-db"
    username            = "admin"
    instance_class      = "db.t4g.micro"
    publicly_accessible = "true"
    snapshot_identifier = "clixxwordpressdb"
    skip_final_snapshot = "true"
  }
} 

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
    Name        = "Clixx-Terraform-Deployment"
    stackTeam   = "stackcloud14"
    OwnerEmail  = "stackawsdeij@gmail.com"
    Environment = "dev"
    Project     = "clixx-web-deployment"
    CostCenter  = "cc1234"
    Application = "clixx-website"
  }
}

variable "vpc_id" {
  description = "The VPC ID where resources will be deployed"
  type        = string
  default     = true
}

variable "sg_name" {
  description = "The name of the security group for the clixx deployment"
  type        = string
  default     = "Clixx_SG"
}

variable "ec2_properties" {
  description = "A map of EC2 instance properties"
  type        = map(string)
  default = {
    name                    = "clixx-web"
    instance_type           = "t2.micro"
    ami_id                  = "ami-0cae6d6fe6048ca2c"
    key_name                = "clixx-kp"
    iam_instance_profile    = "IAM_instance_profile"
  }
}

variable "rds_instance_properties" {
  description = "A map of RDS instance properties"
  type        = map(string)
  default = {
    identifier          = "clixx-db"
    username            = "admin"
    instance_class      = "db.t4g.micro"
    allocated_storage   = "20"
    engine              = "mysql"
    engine_version      = "8.4"
    publicly_accessible = "true"
    snapshot_identifier = "deijwordpressdb"
    skip_final_snapshot = "true"
  }
} 

variable "efs_properties" {
  description = "A map of EFS properties"
  type        = map(string)
  default = {
    creation_token = "clixx-EFS"
    encrypted      = "true"
  }
}
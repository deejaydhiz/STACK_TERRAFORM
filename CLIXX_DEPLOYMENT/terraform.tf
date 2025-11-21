terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.21"
    }
  }

  required_version = ">= 1.2.0"
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"

/*  assume_role {
    role_arn     = "arn:aws:iam::470739596379:role/Engineer"
  }*/
}

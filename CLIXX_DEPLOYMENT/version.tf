terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.21"
    }
    http = {
      source = "hashicorp/http"
    }
  }

  required_version = ">= 1.14.0"
}
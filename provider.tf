# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"

  assume_role {
    role_arn     = "arn:aws:iam::${var.accounts[var.env]}:role/Engineer"
  }
}

# Configure the AWS Provider for management account
provider "aws" {
  alias  = "management"
  region = "us-east-1"

  profile = "stack_prog" 
}
terraform {
  backend "s3" {
    # The name of the S3 bucket where the state file will be stored
    bucket = "deji-stack-states" 

    # The path and filename for the state file within the bucket
    key    = "blog-deployment/dev/terraform.tfstate" 

    # The AWS region where the S3 bucket is located
    region = "us-east-1" 

    # Enable server-side encryption for the state file at rest
    encrypt = true 

    # The name of the DynamoDB table used for state locking to prevent concurrent operations
    //dynamodb_table = "terraform-state-locks" 
  }
}
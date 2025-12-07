# # Create a VPC with 2 private subnets and 2 public subnets 
# resource "aws_vpc" "clixx_vpc" {
#   cidr_block       = "10.0.0.0/16"
#   instance_tenancy = "default"

#   tags = var.tags
# }
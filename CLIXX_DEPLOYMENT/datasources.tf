# Get default vpc_id from AWS

data "aws_vpc" "default" {
  default = true
}

# Get Route 53 hosted zone using its name

data "aws_route53_zone" "clixx_dns" {
  name         = "deji-stack.com."
  private_zone = false
}


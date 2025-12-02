# Get default vpc_id from AWS
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Get Route 53 hosted zone using its name
data "aws_route53_zone" "clixx_dns" {
  provider     = aws.management
  name         = "deji-stack.com"
  private_zone = false
}

data "http" "my_public_ip" {
  url = "https://ipv4.icanhazip.com"
}

 
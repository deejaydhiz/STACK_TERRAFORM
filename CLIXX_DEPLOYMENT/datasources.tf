# Get Route 53 hosted zone using its name

data "aws_route53_zone" "clixx_dns" {
  name         = "deji-stack.com."
  private_zone = false
}


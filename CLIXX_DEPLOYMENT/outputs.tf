# output "subnet_cidr_blocks" {
#   value = [for s in data.aws_subnets.default : s.cidr_block]
# }

# output "subnet_ids" {
#   value = [for s in data.aws_subnets.default : s.id]
# }

# Output the public IP address
output "my_public_ip_address" {
  value = chomp(data.http.my_public_ip.body)
}
# Create the security group for the clixx deployment

resource "aws_security_group" "clixx_sg" {
  name        = var.sg_name
  description = "This is the security group for the clixx deployment"
  vpc_id      = data.aws_vpc.main.id
  tags        = var.tags
}

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.clixx_sg.id
  description = "Allow http access"
  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 80
  ip_protocol = "tcp"
  to_port     = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_https" {
  security_group_id = aws_security_group.clixx_sg.id
  description = "Allow https access"
  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 443
  ip_protocol = "tcp"
  to_port     = 443
}

resource "aws_vpc_security_group_ingress_rule" "allow_rds" {
  security_group_id = aws_security_group.clixx_sg.id
  description = "Allow RDS connection access"
  cidr_ipv4   = data.aws_vpc.main.cidr_block 
  from_port   = 3306
  ip_protocol = "tcp"
  to_port     = 3306
}

resource "aws_vpc_security_group_ingress_rule" "allow_nfs" {
  security_group_id = aws_security_group.clixx_sg.id
  description = "Allow EFS access"
  cidr_ipv4   = data.aws_vpc.main.cidr_block
  from_port   = 2049
  ip_protocol = "tcp"
  to_port     = 2049
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.clixx_sg.id
  description = "Allow SSH access"
  cidr_ipv4   = "${chomp(data.http.my_public_ip.response_body)}/32"
  from_port   = 22
  ip_protocol = "tcp"
  to_port     = 22
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.clixx_sg.id
  description = "Allow all outbound traffic"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

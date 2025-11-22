### Create parameters in Parameter store for use in clixx user data ###
resource "aws_ssm_parameter" "clixx_lb" {
  name  = "/clixx/LB"
  type  = "String"
  value = aws_lb.clixx_lb.dns_name
}

resource "aws_ssm_parameter" "clixx_db" {
  name  = "/clixx/DB"
  type  = "String"
  value = aws_db_instance.clixx_db.address
}

resource "aws_ssm_parameter" "clixx_efs" {
  name  = "/clixx/EFS"
  type  = "String"
  value = aws_efs_file_system.clixx_efs.dns_name
}


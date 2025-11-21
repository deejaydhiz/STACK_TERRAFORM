# Restores the database from the provided snapshot 

resource "aws_db_instance" "clixx_db" {
  instance_class          = "db.t4g.micro"
  identifier              = "terraform-clixx-db"
  snapshot_identifier     = "clixxwordpressdb"
  skip_final_snapshot     = true
  vpc_security_group_ids  = [aws_security_group.clixx_sg.id]

  lifecycle {
    ignore_changes = [snapshot_identifier]
  }
}


# Create EFS for for clixx network file sharing 

resource "aws_efs_file_system" "clixx_efs" {
  creation_token    = "clixx-web"
  encrypted         = true

  tags = {
    Name = "Clixx-EFS"
  }
}

# Attach EFS to mount targets in each az for high availability

resource "aws_efs_mount_target" "east1a" {
  file_system_id  = aws_efs_file_system.clixx_efs.id
  subnet_id       = "subnet-0a3d701d4ae56bd83"
  security_groups = [aws_security_group.clixx_sg.id]
}

resource "aws_efs_mount_target" "east1b" {
  file_system_id  = aws_efs_file_system.clixx_efs.id
  subnet_id       = "subnet-096c55d1b79478358"
  security_groups = [aws_security_group.clixx_sg.id]
}

resource "aws_efs_mount_target" "east1c" {
  file_system_id  = aws_efs_file_system.clixx_efs.id
  subnet_id       = "subnet-02b9ff9a66612dba1"
  security_groups = [aws_security_group.clixx_sg.id]
}

resource "aws_efs_mount_target" "east1d" {
  file_system_id  = aws_efs_file_system.clixx_efs.id
  subnet_id       = "subnet-0cea1d9a41e99ed45"
  security_groups = [aws_security_group.clixx_sg.id]
}

resource "aws_efs_mount_target" "east1e" {
  file_system_id  = aws_efs_file_system.clixx_efs.id
  subnet_id       = "subnet-00a91d6c6d1743e8f"
  security_groups = [aws_security_group.clixx_sg.id]
}

resource "aws_efs_mount_target" "east1f" {
  file_system_id  = aws_efs_file_system.clixx_efs.id
  subnet_id       = "subnet-05393b0e3f17eeeae"
  security_groups = [aws_security_group.clixx_sg.id]
}


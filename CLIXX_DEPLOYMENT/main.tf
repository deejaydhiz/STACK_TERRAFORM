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

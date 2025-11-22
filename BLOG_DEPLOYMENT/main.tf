resource "aws_db_instance" "blog_db" {
  instance_class      = "db.t4g.micro"
  identifier          = "blog-db"
  snapshot_identifier = "deijwordpress"
  skip_final_snapshot = true

  lifecycle {
    ignore_changes = [snapshot_identifier]
  }
}

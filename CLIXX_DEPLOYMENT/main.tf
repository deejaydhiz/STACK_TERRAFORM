#### Restores the database from the provided snapshot ####

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


### Create EFS for for clixx network file sharing ###

resource "aws_efs_file_system" "clixx_efs" {
  creation_token    = "clixx-web"
  encrypted         = true

  tags = {
    Name = "Clixx-EFS"
  }
}

### Attach EFS to mount targets in each az for high availability ###

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

### Application Load Balancer ###

resource "aws_lb" "clixx_lb" {
  name               = "clixx-lb-tf"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.clixx_sg.id]
  subnets            = ["subnet-0a3d701d4ae56bd83", "subnet-096c55d1b79478358", "subnet-02b9ff9a66612dba1", "subnet-0cea1d9a41e99ed45", "subnet-00a91d6c6d1743e8f", "subnet-05393b0e3f17eeeae"]

  tags = {
    Environment = "dev"
    Name        = "Clixx LB"
    CreatedBy   = "Deji using Terraform"
  }
}

### Target group for load balancer ###

resource "aws_lb_target_group" "clixx_tg" {
  name     = "tf-clixx-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id
}

### LB listener, forwards HTTP requests to target group ###

resource "aws_lb_listener" "clixx_front-end" {
  load_balancer_arn = aws_lb.clixx_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.clixx_tg.arn
  }
}

### Resolve Load Balancer DNS to our Route 53 domain (clixx.deji-stack.com) ###

resource "aws_route53_record" "clixx_dns" {
  zone_id = data.aws_route53_zone.clixx_dns.zone_id
  name    = "clixx.${data.aws_route53_zone.clixx_dns.name}"
  type    = "A"

  alias {
    name                   = aws_lb.clixx_lb.dns_name
    zone_id                = aws_lb.clixx_lb.zone_id
    evaluate_target_health = true
  }
}

### Create key pair ###

resource "aws_key_pair" "clixx_kp" {
  key_name   = "terraform-kp"
  public_key = file("~/.ssh/terraform-key.pub")
}

### Create Auto Scaling Group ###

resource "aws_autoscaling_group" "clixx_asg" {
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d", "us-east-1e", "us-east-1f"]
  desired_capacity   = 1
  max_size           = 2
  min_size           = 1
  target_group_arns  = [aws_lb_target_group.clixx_tg.arn]

  launch_template {
    id      = aws_launch_template.clixx_template.id
    version = "$Latest"
  }
}


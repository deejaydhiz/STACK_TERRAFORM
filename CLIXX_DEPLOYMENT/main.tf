#### Restores the database from the provided snapshot ####
resource "aws_db_instance" "clixx_db" {
  instance_class          = var.rds_instance_properties["instance_class"]
  identifier              = var.rds_instance_properties["identifier"]
  snapshot_identifier     = var.rds_instance_properties["snapshot_identifier"]
  skip_final_snapshot     = var.rds_instance_properties["skip_final_snapshot"]
  vpc_security_group_ids  = [aws_security_group.clixx_sg.id]
  publicly_accessible     = var.rds_instance_properties["publicly_accessible"]

  lifecycle {
    ignore_changes = [snapshot_identifier]
  }
}

### Create EFS for for clixx network file sharing ###
resource "aws_efs_file_system" "clixx_efs" {
  creation_token    = var.efs_properties["creation_token"]
  encrypted         = var.efs_properties["encrypted"]

  tags = var.tags
}

### Attach EFS to mount targets in each az for high availability ###
resource "aws_efs_mount_target" "subnet_mounts" {
  for_each = toset(data.aws_subnets.default.ids)
  file_system_id  = aws_efs_file_system.clixx_efs.id
  subnet_id       = each.value
  security_groups = [aws_security_group.clixx_sg.id]
}

### Application Load Balancer ###
resource "aws_lb" "clixx_lb" {
  name               = var.ec2_properties["name"]
  load_balancer_type = "application"
  security_groups    = [aws_security_group.clixx_sg.id]
  subnets            = data.aws_subnets.default.ids
  tags               = var.tags
}

### Target group for load balancer ###
resource "aws_lb_target_group" "clixx_tg" {
  name     = var.ec2_properties["name"]
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.main.id
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
  provider = aws.management
  zone_id  = data.aws_route53_zone.clixx_dns.zone_id
  name     = "clixx.${data.aws_route53_zone.clixx_dns.name}"
  type     = "A"

  alias {
    name                   = aws_lb.clixx_lb.dns_name
    zone_id                = aws_lb.clixx_lb.zone_id
    evaluate_target_health = true
  }
}

### Create keypair ###
resource "aws_key_pair" "clixx_kp" {
  key_name   = "clixx-kp"
  # Read the public key from a path provided via variable. Place the .pub file in the repo
  # or pass its path via -var "public_key_path=./keys/clixx-kp.pub" from CI.
  public_key = file(var.public_key_path)
}

### Create Auto Scaling Group ###
resource "aws_autoscaling_policy" "clixx_scaling_policy" {
  name                   = "clixx-scale-out-policy"
  policy_type            = "TargetTrackingScaling"
  adjustment_type        = "ChangeInCapacity"
  autoscaling_group_name = aws_autoscaling_group.clixx_asg.name

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 50.0
  }
}

resource "aws_autoscaling_group" "clixx_asg" {
  vpc_zone_identifier = data.aws_subnets.default.ids
  name                = var.ec2_properties["name"]
  desired_capacity   = 1
  max_size           = 2
  min_size           = 1
  target_group_arns  = [aws_lb_target_group.clixx_tg.arn]
  
  depends_on = [aws_db_instance.clixx_db]

  launch_template {
    id      = aws_launch_template.clixx_template.id
    version = "$Latest"
  }
}


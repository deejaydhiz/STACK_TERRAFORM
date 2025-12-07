resource "aws_launch_template" "clixx_template" {
  name = "clixx-web"
  image_id = "ami-0cae6d6fe6048ca2c"
  instance_type = "t2.micro"
  key_name = "clixx-kp"
  vpc_security_group_ids = [aws_security_group.clixx_sg.id]
  
  iam_instance_profile {
    name = "IAM_instance_profile"
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "clixx-tf-instance"
    }
  }
  user_data = filebase64("${path.module}/scripts/clixxbootstrap.sh")
}
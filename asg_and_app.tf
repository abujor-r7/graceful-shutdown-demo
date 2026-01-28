resource "aws_security_group" "sg" {
  name   = "${var.prefix}-sg"
  vpc_id = data.aws_vpc.selected.id
  egress { 
    from_port = 0
    to_port = 0
    protocol = "-1" 
    cidr_blocks = ["0.0.0.0/0"] 
  }
}

resource "aws_launch_template" "lt" {
  name_prefix = "${var.prefix}-lt"
  image_id    = "ami-0faab6bdbac9486fb"
  instance_type = "t2.micro"
  iam_instance_profile { name = aws_iam_instance_profile.ec2_profile.name }
  network_interfaces { 
    associate_public_ip_address = true
    security_groups = [aws_security_group.sg.id] 
  }
  user_data = base64encode(file("${path.module}/scripts/user_data.sh"))
}

resource "aws_autoscaling_group" "asg" {
  name                = "${var.prefix}-asg"
  desired_capacity    = 2
  max_size            = 3
  min_size            = 1
  vpc_zone_identifier = data.aws_subnets.selected.ids
  launch_template { 
    id = aws_launch_template.lt.id
    version = "$Latest" 
  }
}

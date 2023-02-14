# --- compute/main.tf ---

data "aws_ami" "linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.linux.id
  key_name               = "aws_seoul_key"
  instance_type          = var.web_instance_type
  vpc_security_group_ids = [var.web_sg]
  availability_zone      = "ap-northeast-2a"
  subnet_id              = var.public_subnet
  user_data              = filebase64("install_apache.sh")

  tags = {
    Name = "web"
  }
}

# resource "aws_autoscaling_group" "web" {
#   name                = "web"
#   vpc_zone_identifier = tolist(var.public_subnet)
#   min_size            = 2
#   max_size            = 3
#   desired_capacity    = 2

#   launch_template {
#     id      = aws_launch_template.web.id
#     version = "$Latest"
#   }
# }


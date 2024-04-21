#fetch latest ec2 ubuntu ami
data "aws_ami" "latest_ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = [var.image_name]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


#creating ssh key pair
resource "aws_key_pair" "myapp_ssh_key" {
  key_name   = "server-key"
  public_key = file(var.public_key_path)
}

# creating ec2 instance
resource "aws_instance" "myapp_instance" {
  ami           = data.aws_ami.latest_ubuntu.id
  instance_type = var.instance_type

  subnet_id              = var.subnet_id #module.myapp-subnet.subnet-output.id
  vpc_security_group_ids = [aws_security_group.myapp_sg.id]
  #[aws_default_security_group.default_sg.id]
  availability_zone = var.avail_zone

  associate_public_ip_address = true
  #ssh keyname
  key_name = aws_key_pair.myapp_ssh_key.key_name

  # installing package in ec2
  user_data = file("entry-script.sh")

  tags = {
    Name : "${var.env_prefix}-server"
  }
}


# creating security group
resource "aws_security_group" "myapp_sg" {
  vpc_id = var.vpc_id
  tags = {
    Name : "myapp-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_myapp_ssh" {
  security_group_id = aws_security_group.myapp_sg.id
  cidr_ipv4         = var.my_ip
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22

}

resource "aws_vpc_security_group_ingress_rule" "allow_myapp_traffic" {
  security_group_id = aws_security_group.myapp_sg.id
  from_port         = 8080
  ip_protocol       = "tcp"
  to_port           = 8080
  cidr_ipv4         = "0.0.0.0/0"

}

resource "aws_vpc_security_group_egress_rule" "allow_myapp_all_traffic" {
  security_group_id = aws_security_group.myapp_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  # from_port         = 0
  ip_protocol = "-1"
  # to_port           = 0

}

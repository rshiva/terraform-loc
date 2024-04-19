provider "aws" {
  region = "ap-south-1"
}

variable "vpc_cidr_block" {}
variable "subnet_cidr_block" {}
variable "avail_zone" {}
variable "env_prefix" {}
variable "my_ip" {}
variable "instance_type" {}
variable "public_key_path" {}


resource "aws_vpc" "myapp_vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name : "${var.env_prefix}-vpc"
  }
}

resource "aws_subnet" "myapp-subnet-1" {
  vpc_id            = aws_vpc.myapp_vpc.id
  cidr_block        = var.subnet_cidr_block
  availability_zone = var.avail_zone
  tags = {
    Name : "${var.env_prefix}-subnet-1"
  }
}

# resource "aws_route_table" "myapp_route_table" {
#   vpc_id = aws_vpc.myapp_vpc.id

#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.myapp_igw.id
#   }
#   tags = {
#     Name : "${var.env_prefix}-rtb"
#   }
# }

resource "aws_internet_gateway" "myapp_igw" {
  vpc_id = aws_vpc.myapp_vpc.id
  tags = {
    Name : "${var.env_prefix}-igw"
  }
}


# resource "aws_route_table_association" "a-rtb-subnet" {
#   subnet_id      = aws_subnet.myapp-subnet-1.id
#   route_table_id = aws_route_table.myapp_route_table.id
# }

resource "aws_default_route_table" "main_rtb" {
  default_route_table_id = aws_vpc.myapp_vpc.default_route_table_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp_igw.id
  }
  tags = {
    Name : "${var.env_prefix}-rtb"
  }
}


# creating security group
resource "aws_default_security_group" "default_sg" {
  vpc_id = aws_vpc.myapp_vpc.id
  tags = {
    Name : "${var.env_prefix}-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_myapp_ssh" {
  security_group_id = aws_default_security_group.default_sg.id
  cidr_ipv4         = var.my_ip
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22

}

resource "aws_vpc_security_group_ingress_rule" "allow_myapp_traffic" {
  security_group_id = aws_default_security_group.default_sg.id
  from_port         = 8080
  ip_protocol       = "tcp"
  to_port           = 8080
  cidr_ipv4         = "0.0.0.0/0"

}

resource "aws_vpc_security_group_egress_rule" "allow_myapp_all_traffic" {
  security_group_id = aws_default_security_group.default_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  # from_port         = 0
  ip_protocol = "-1"
  # to_port           = 0

}

#fetch latest ec2 ubuntu ami
data "aws_ami" "latest_ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# output "aws_ami_id" {
#   value = data.aws_ami.latest_ubuntu
# }
# creating ec2 instance

#creating ssh key pair
resource "aws_key_pair" "myapp_ssh_key" {
  key_name   = "server-key"
  public_key = file(var.public_key_path)
}

output "ec2_public_ip" {
  value = aws_instance.myapp_instance.public_ip
}

resource "aws_instance" "myapp_instance" {
  ami           = data.aws_ami.latest_ubuntu.id
  instance_type = var.instance_type

  subnet_id              = aws_subnet.myapp-subnet-1.id
  vpc_security_group_ids = [aws_default_security_group.default_sg.id]
  availability_zone      = var.avail_zone

  associate_public_ip_address = true
  #ssh keyname
  key_name = aws_key_pair.myapp_ssh_key.key_name

  # installing package in ec2
  user_data = file("entry-script.sh")

  tags = {
    Name : "${var.env_prefix}-server"
  }
}

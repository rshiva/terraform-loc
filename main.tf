provider "aws" {
  region = "ap-south-1"
}

resource "aws_vpc" "myapp_vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name : "${var.env_prefix}-vpc"
  }
}

# call subnet module
module "myapp-subnet" {
  source                 = "./modules/subnet"
  vpc_id                 = aws_vpc.myapp_vpc.id
  subnet_cidr_block      = var.subnet_cidr_block
  avail_zone             = var.avail_zone
  env_prefix             = var.env_prefix
  my_ip                  = var.my_ip
  default_route_table_id = aws_vpc.myapp_vpc.default_route_table_id
}


module "myapp-ec2instance" {
  source          = "./modules/webserver"
  vpc_id          = aws_vpc.myapp_vpc.id
  my_ip           = var.my_ip
  image_name      = var.image_name
  public_key_path = var.public_key_path
  instance_type   = var.instance_type
  subnet_id       = module.myapp-subnet.subnet-output.id
  avail_zone      = var.avail_zone
  env_prefix      = var.env_prefix
}

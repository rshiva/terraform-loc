provider "aws" {
  region = "ap-south-1"
}


module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "myapp_vpc"
  cidr = var.vpc_cidr_block

  azs                = ["ap-south-1a"]
  public_subnets     = [var.subnet_cidr_block]
  public_subnet_tags = { Name = "${var.env_prefix}-subnet-1" }

  tags = {
    Name = "${var.env_prefix}-vpc"
  }
}


module "myapp-ec2instance" {
  source          = "./modules/webserver"
  vpc_id          = module.vpc.vpc_id
  my_ip           = var.my_ip
  image_name      = var.image_name
  public_key_path = var.public_key_path
  instance_type   = var.instance_type
  subnet_id       = module.vpc.public_subnets[0]
  avail_zone      = var.avail_zone
  env_prefix      = var.env_prefix
}

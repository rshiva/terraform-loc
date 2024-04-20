output "ec2_public_ip" {
  value = module.myapp-ec2instance.instance.public_ip
}

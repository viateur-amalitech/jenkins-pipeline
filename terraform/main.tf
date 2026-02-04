provider "aws" {
  region = var.aws_region
}

module "web_server" {
  source        = "./modules/ec2"
  instance_type = var.instance_type
  key_name      = var.key_name
}

output "web_server_public_ip" {
  value = module.web_server.public_ip
}

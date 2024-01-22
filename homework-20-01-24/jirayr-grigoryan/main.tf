provider "aws" {
  region = var.region
}

terraform {
  backend "s3" {
    bucket = "jirodevops"
    key    = "backend"
    region = "eu-west-2"
  }
} 


module "vpc" {
  source = "./modules/vpc"
}

module "networking" {
  source             = "./modules/networking"
  vpc_id             = module.vpc.vpc_id
}

module "ec2" {
  source            = "./modules/ec2"
  subnet_id         = module.networking.subnet_id
  security_group_id = module.networking.security_group_id
  key_name          = var.key_pair_name
  ami_id = var.ami_id
  instance_type = var.instance_type	
}



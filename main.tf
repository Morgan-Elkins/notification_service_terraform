provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.14.0"

  cidr = var.vpc_cidr_block

  azs             = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
  private_subnets = slice(var.private_subnet_cidr_blocks, 0, 2)
  public_subnets  = slice(var.public_subnet_cidr_blocks, 0, 2)

  enable_nat_gateway = true
  enable_vpn_gateway = false

  map_public_ip_on_launch = false
}
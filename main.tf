provider "aws" {
  region = var.aws_region
}

# Filter out local zones, which are not currently supported with managed node groups
data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name = "notification-service-vpc"

  cidr = var.vpc_cidr_block

  azs             = slice(data.aws_availability_zones.available.names, 0, 3)
  private_subnets = slice(var.private_subnet_cidr_blocks, 0, 3)
  public_subnets  = slice(var.public_subnet_cidr_blocks, 0, 3)
  intra_subnets   = slice(var.intra_subnet_cidr_blocks, 0, 3)

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  map_public_ip_on_launch = false

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
}
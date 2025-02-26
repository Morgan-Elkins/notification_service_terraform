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

  intra_subnet_tags = {
    "kubernetes.io/role/internal-networking" = 1
  }
}

# module "app_security_group" {
#   source  = "terraform-aws-modules/security-group/aws//modules/web"
#   version = "5.1.2"

#   name        = "web-sg-${var.resource_tags["project"]}-${var.resource_tags["environment"]}"
#   description = "Security group for web-servers with HTTP ports open within VPC"
#   vpc_id      = module.vpc.vpc_id

#   ingress_cidr_blocks = module.vpc.public_subnets_cidr_blocks

#   tags = var.resource_tags
# }

# module "lb_security_group" {
#   source  = "terraform-aws-modules/security-group/aws//modules/web"
#   version = "5.1.2"

#   name        = "lb-sg-${var.resource_tags["project"]}-${var.resource_tags["environment"]}"
#   description = "Security group for load balancer with HTTP ports open within VPC"
#   vpc_id      = module.vpc.vpc_id

#   ingress_cidr_blocks      = ["0.0.0.0/0"]
#   ingress_with_cidr_blocks = [aws_security_group_rule.icmp_security_group_rule]

#   tags = var.resource_tags
# }

module "service_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.2"

  name        = "service-sg-${var.resource_tags["project"]}-${var.resource_tags["environment"]}"

  ingress_with_cidr_blocks = [aws_security_group_rule.icmp_security_group_rule,
    aws_security_group_rule.tcp_security_group_rule,
    aws_security_group_rule.udp_security_group_rule
  ]

  egress_with_cidr_blocks = [aws_security_group_rule.external_security_group_rule]

  description = "Security group for allowing interal commuication in the VPC"

}

resource "aws_security_group_rule" "icmp_security_group_rule" {
  type              = "ingress"
  description       = "Allow all incoming ICMP - IPv4 traffic"
  from_port         = -1
  to_port           = -1
  protocol          = "icmp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "sg-123456-icmp"
}

resource "aws_security_group_rule" "tcp_security_group_rule" {
  type              = "ingress"
  description       = "Allow internal HTTP(S) and service communication"
  from_port         = 80
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "sg-123456-tcp"
}

resource "aws_security_group_rule" "udp_security_group_rule" {
  type              = "ingress"
  description       = "Allow internal UDP traffic"
  from_port         = 80
  to_port           = 65535
  protocol          = "udp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "sg-123456-udp"
}

resource "aws_security_group_rule" "external_security_group_rule" {
  type              = "egress"
  description       = "Allow outbound traffic to the internet"
  from_port         = -1
  to_port           = -1
  protocol          = "all"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "sg-123456-egress"
}
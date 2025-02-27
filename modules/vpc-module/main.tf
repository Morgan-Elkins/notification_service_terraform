# resource "aws_security_group_rule" "icmp_security_group_rule" {
#   type              = "ingress"
#   description       = "Allow all incoming ICMP - IPv4 traffic"
#   from_port         = -1
#   to_port           = -1
#   protocol          = "icmp"
#   cidr_blocks       = ["0.0.0.0/0"]
#   security_group_id = "sg-123456-icmp"
# }

# resource "aws_security_group_rule" "tcp_security_group_rule" {
#   type              = "ingress"
#   description       = "Allow internal HTTP(S) and service communication"
#   from_port         = 80
#   to_port           = 65535
#   protocol          = "tcp"
#   cidr_blocks       = ["0.0.0.0/0"]
#   security_group_id = "sg-123456-tcp"
# }

# resource "aws_security_group_rule" "udp_security_group_rule" {
#   type              = "ingress"
#   description       = "Allow internal UDP traffic"
#   from_port         = 80
#   to_port           = 65535
#   protocol          = "udp"
#   cidr_blocks       = ["0.0.0.0/0"]
#   security_group_id = "sg-123456-udp"
# }

# resource "aws_security_group_rule" "external_security_group_rule" {
#   type              = "egress"
#   description       = "Allow outbound traffic to the internet"
#   from_port         = -1
#   to_port           = -1
#   protocol          = "all"
#   cidr_blocks       = ["0.0.0.0/0"]
#   security_group_id = "sg-123456-egress"
# }

# Filter out local zones, which are not currently supported with managed node groups
data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  cluster_name = "notification-service-eks-${random_string.suffix.result}"
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}


module "vpc_source" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name = "notification-service-vpc"

  cidr = var.vpc_cidr_block

  azs             = slice(data.aws_availability_zones.available.names, 0, 3)
  private_subnets = slice(var.private_subnet_cidr_blocks, 0, 3)
  public_subnets  = slice(var.public_subnet_cidr_blocks, 0, 3)
  intra_subnets   = slice(var.intra_subnet_cidr_blocks, 0, 3)

  enable_nat_gateway   = true # Change to true
  single_nat_gateway   = true # Change to true?
  enable_dns_hostnames = true  # Change to true

  map_public_ip_on_launch = false # Change to true?

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  intra_subnet_tags = {
    Name = "${local.cluster_name}-intra"
  }
}

module "service_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.2"

  vpc_id = module.vpc_source.vpc_id

  name = "service-sg-${var.resource_tags["project"]}-${var.resource_tags["environment"]}"

  ingress_with_cidr_blocks = [{
    type              = "ingress"
    description       = "Allow all incoming ICMP - IPv4 traffic"
    from_port         = -1
    to_port           = -1
    protocol          = "icmp"
    cidr_blocks       = "0.0.0.0/0"
    security_group_id = "sg-123456-icmp"
    tag               = "notification-service-vpc-ICMP"
    },
    {
      type              = "ingress"
      description       = "Allow internal HTTP(S) and service communication"
      from_port         = 80
      to_port           = 65535
      protocol          = "tcp"
      cidr_blocks       = "0.0.0.0/0"
      security_group_id = "sg-123456-tcp"
      tag               = "notification-service-vpc-TCP"
    },
    {
      type              = "ingress"
      description       = "Allow internal UDP traffic"
      from_port         = 80
      to_port           = 65535
      protocol          = "udp"
      cidr_blocks       = "0.0.0.0/0"
      security_group_id = "sg-123456-udp"
      tag               = "notification-service-vpc-UDP"
    }
  ]

  egress_with_cidr_blocks = [{
    type              = "egress"
    description       = "Allow outbound traffic to the internet"
    from_port         = -1
    to_port           = -1
    protocol          = "all"
    cidr_blocks       = "0.0.0.0/0"
    security_group_id = "sg-123456-egress"
    tag               = "notification-service-vpc-egress"
  }]

  description = "Security group for allowing interal commuication in the VPC"

}

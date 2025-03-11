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

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 3)
  private_subnets = [for k, v in local.azs : cidrsubnet(var.vpc_cidr_block, 4, k)]
  public_subnets = [for k, v in local.azs : cidrsubnet(var.vpc_cidr_block, 8, k + 48)]
  intra_subnets  = [for k, v in local.azs : cidrsubnet(var.vpc_cidr_block, 8, k + 52)]
}

# Filter out local zones, which are not currently supported with managed node groups
data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  cluster_name = "morgan_eks_cluster"
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}


module "vpc_source" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name = "morgan-notification-service-vpc"

  cidr = var.vpc_cidr_block

  azs             = local.azs
  private_subnets = local.private_subnets
  public_subnets  = local.public_subnets
  intra_subnets   = local.intra_subnets

  enable_nat_gateway   = true # Change to true
  single_nat_gateway   = true # Change to true
  enable_dns_hostnames = true  # Change to true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
    Name = "${local.cluster_name}-public"
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
    Name = "${local.cluster_name}-private"
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
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
    cidr_blocks       = "10.0.0.0/16"
    tag               = "notification-service-vpc-ICMP"
    },
    {
      type              = "ingress"
      description       = "Allow internal HTTP(S) and service communication"
      from_port         = 80
      to_port           = 65535
      protocol          = "tcp"
      cidr_blocks       = "10.0.0.0/16"
      tag               = "notification-service-vpc-TCP"
    },
    {
      type              = "ingress"
      description       = "Allow internal UDP traffic"
      from_port         = 80
      to_port           = 65535
      protocol          = "udp"
      cidr_blocks       = "10.0.0.0/16"
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
    tag               = "notification-service-vpc-egress"
  }]

  description = "Security group for allowing interal commuication in the VPC"

}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      environment = "prod"
      managed_by  = "terraform"
      project     = "notification-service"
      cost_tag    = "notification-service"
    }
  }
}


module "vpc" {
  source = "./modules/vpc-module"
}

module "iam" {
  source        = "./modules/iam-module"
  oidc_provider = module.eks.oidc_provider
}

module "sqs" {
  source = "./modules/sqs-module"
}

module "eks" {
  source                  = "./modules/eks-module"
  module_vpc              = module.vpc.vpc_obj
  external_dns_policy_arn = module.iam.external_dns_policy_arn
  cluster_name            = module.vpc.cluster_name
  public_subnet_ids       = module.vpc.public_subnet_ids
  private_subnet_ids      = module.vpc.private_subnet_ids
  intra_subnet_ids        = module.vpc.intra_subnet_ids
  assume_role_policy      = module.iam.assume_role_policy
}

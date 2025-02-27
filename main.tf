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
  source = "./modules/iam-module"
}

module "sqs" {
  source = "./modules/sqs-module"
}

module "eks" {
  source = "./modules/eks-module"
}

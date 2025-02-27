# module "eks" {
#   source  = "terraform-aws-modules/eks/aws"
#   version = "~> 20.0"

#   cluster_name    = "Notification_service_eks_cluster"
#   cluster_version = "1.31"

#   bootstrap_self_managed_addons = false
#   cluster_addons = {
#     coredns                = {}
#     eks-pod-identity-agent = {}
#     kube-proxy             = {}
#     vpc-cni                = {}
#   }

#     # Optional
#   cluster_endpoint_public_access = false # true?

#   # Optional: Adds the current caller identity as an administrator via cluster access entry
#   enable_cluster_creator_admin_permissions = false # true?

#   vpc_id     = module.vpc_id
#   subnet_ids = [module.public_subnets]
#   control_plane_subnet_ids = [module.intra_subnet_ids]



# }
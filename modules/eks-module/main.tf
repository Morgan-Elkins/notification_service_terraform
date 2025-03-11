data "aws_caller_identity" "current" {}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "morgan_eks_cluster"
  cluster_version = "1.31"

  vpc_id                   = var.module_vpc.vpc_id
  subnet_ids               = var.private_subnet_ids
  control_plane_subnet_ids = var.intra_subnet_ids

  authentication_mode = "API_AND_CONFIG_MAP"

  enable_cluster_creator_admin_permissions = true
  cluster_endpoint_public_access           = true

  enable_irsa = true

  #   bootstrap_self_managed_addons = false
  cluster_addons = {
    coredns = {
      most_recent       = true
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {
      most_recent       = true
      resolve_conflicts = "OVERWRITE"
    }
    vpc-cni = {
      most_recent       = true
      resolve_conflicts = "OVERWRITE"
    }
    aws-ebs-csi-driver = {
      service_account_role_arn = var.ebs-arn
    }
  }

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    instance_types = ["t3.medium"]
  }

  eks_managed_node_groups = {
    morgan_node_group_1 = {
      cluster_name   = "${var.cluster_name}-node_group_1"
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["t3.medium"]

      subnet_id = var.private_subnet_ids[0]

      min_size     = 1
      max_size     = 1
      desired_size = 1

      launch_template = {
        root_volume_type = "gp2"
        root_volume_size = 20
      }

      additional_policies = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]

      tags = {
        "name" = "${var.cluster_name}"
      }

      labels = {
        "managed_by" = "terraform"
        "k8s-app" = "notification-service"
      }
    }
    # node_group_2 = {
    #   cluster_name   = "${var.cluster_name}-node_group_2"
    #   ami_type       = "AL2023_x86_64_STANDARD"
    #   instance_types = ["t3.medium"]

    #   subnet_id = var.private_subnet_ids[1]

    #   min_size     = 1
    #   max_size     = 1
    #   desired_size = 1

    #   launch_template = {
    #     root_volume_type = "gp2"
    #     root_volume_size = 20
    #   }      
    # }
    # node_group_3 = {
    #   cluster_name   = "${var.cluster_name}-node_group_3"
    #   ami_type       = "AL2023_x86_64_STANDARD"
    #   instance_types = ["t3.medium"]

    #   subnet_id = var.private_subnet_ids[2]

    #   min_size     = 1
    #   max_size     = 1
    #   desired_size = 1

    #   launch_template = {
    #     root_volume_type = "gp2"
    #     root_volume_size = 20
    #   }  
    # }
  }
}

module "ebs_csi_controller_role" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "5.11.1"
  create_role                   = true
  role_name                     = "${var.cluster_name}-ebs-csi-controller"
  provider_url                  = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns              = [var.external_dns_policy_arn]
  oidc_fully_qualified_subjects = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${module.eks.oidc_provider}"]
}

resource "aws_iam_role_policy_attachment" "eks_policy_attachment_systems" {
  for_each = module.eks.eks_managed_node_groups

  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = each.value.iam_role_name
}

resource "aws_iam_policy" "eks_policy_attachment_ecr_read_policy" {
  name        = "${var.cluster_name}-sqs-queue-policy"
  description = "AWS SQS queues policy"

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "ecr:GetAuthorizationToken",
            "ecr:BatchGetImage",
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchImportUpstreamImage"
          ],
          "Resource" : ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${data.aws_caller_identity.current.user_id}"]
        }
      ]
    }
  )
}

resource "aws_iam_role" "eks_policy_attachment_ecr_read_role" {
  name        = "${var.cluster_name}-ecr_read"
  description = "External DNS role"

  assume_role_policy  = var.assume_role_policy
  managed_policy_arns = [aws_iam_policy.eks_policy_attachment_ecr_read_policy.arn]
}

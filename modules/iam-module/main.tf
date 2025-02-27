data "aws_caller_identity" "current" {}

resource "random_string" "policy_prefix" {
  length  = 8
  special = false
}

#
# POLICIES
#
resource "aws_iam_policy" "external_dns_policy" {
  name        = "${random_string.policy_prefix.id}-external_dns_policy"
  description = "External DNS policy"

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "route53:*",
            "route53domains:*",
            "tag:*"
          ],
          "Resource" : "*"
        },
        {
          "Effect" : "Allow",
          "Action" : "apigateway:GET",
          "Resource" : "arn:aws:apigateway:*::/domainnames"
        }
      ]
    }
  )
}

resource "aws_iam_policy" "ebs_csi_driver_policy" {
  name        = "${random_string.policy_prefix.id}-ebs_csi_driver_policy"
  description = "EBS CSI Driver policy"

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "kms:CreateGrant",
            "kms:ListGrants",
            "kms:RevokeGrant"
          ],
          "Resource" : ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${data.aws_caller_identity.current.user_id}"],
          "Condition" : {
            "Bool" : {
              "kms:GrantIsForAWSResource" : "true"
            }
          }
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "kms:Encrypt",
            "kms:Decrypt",
            "kms:ReEncrypt*",
            "kms:GenerateDataKey*",
            "kms:DescribeKey"
          ],
          "Resource" : ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${data.aws_caller_identity.current.user_id}"]
        }
      ]
    }
  )
}

resource "aws_iam_policy" "ecr_repository_policy" {
  name        = "${random_string.policy_prefix.id}-external-dns-policy"
  description = "AWS ECR repo policy"

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage",
            "ecr:BatchCheckLayerAvailability",
            "ecr:PutImage",
            "ecr:InitiateLayerUpload",
            "ecr:UploadLayerPart",
            "ecr:CompleteLayerUpload",
            "ecr:DescribeRepositories",
            "ecr:GetRepositoryPolicy",
            "ecr:ListImages",
            "ecr:DeleteRepository",
            "ecr:BatchDeleteImage",
            "ecr:SetRepositoryPolicy",
            "ecr:DeleteRepositoryPolicy"
          ],
          "Resource" : ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${data.aws_caller_identity.current.user_id}"]
        }
      ]
    }
  )
}

resource "aws_iam_policy" "sqs_queue_policy" {
  name        = "${random_string.policy_prefix.id}-sqs-queue-policy"
  description = "AWS SQS queues policy"

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "sqs:CreateQueue",
            "sqs:DeleteMessage",
            "sqs:DeleteQueue",
            "sqs:GetQueueAttributes",
            "sqs:ReceiveMessage",
            "sqs:SendMessage"
          ],
          "Resource" : ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${data.aws_caller_identity.current.user_id}"]
        }
      ]
    }
  )
}

#
# ROLES
#

# DONT DELETE - commented out due to EKS not on yet
# module "iam_eks_role" {
#   source = "terraform-aws-modules/iam/aws//modules/iam-eks-role"

#   role_name = "${random_string.policy_prefix.id}-iam-eks-role"

#   cluster_service_accounts = {
#     "cluster1" = ["${var.aws_namespace}:role_eks_labsnow"]
#   }
# }

module "iam_eks_role_lb_controller" {
  source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  role_name = "${random_string.policy_prefix.id}-AmazonEKS_LoadBalancer_Controller_Role"

  attach_load_balancer_controller_policy = true

  oidc_providers = {
    one = {
      provider_arn               = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${var.oidc_provider}"
      namespace_service_accounts = ["${var.aws_namespace}:aws-load-balancer-controller"]
    }
  }
}

data "aws_iam_policy_document" "instance_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${var.oidc_provider}"]
    }
  }
}

resource "aws_iam_role" "external_dns_role" {
  name        = "external_dns"
  description = "External DNS role"

  assume_role_policy  = data.aws_iam_policy_document.instance_assume_role_policy.json
  managed_policy_arns = [aws_iam_policy.external_dns_policy.arn]
}

resource "aws_iam_role" "ebs_csi_role" {
  name        = "ebs_csi_role"
  description = "EBS CSI role"

  assume_role_policy  = data.aws_iam_policy_document.instance_assume_role_policy.json
  managed_policy_arns = [aws_iam_policy.ebs_csi_driver_policy.arn]
}

resource "aws_iam_role" "sqs_role" {
  name        = "sqs_role"
  description = "SQS role"

  assume_role_policy  = data.aws_iam_policy_document.instance_assume_role_policy.json
  managed_policy_arns = [aws_iam_policy.sqs_queue_policy.arn]
}

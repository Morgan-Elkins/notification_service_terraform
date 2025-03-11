data "aws_caller_identity" "current" {}

resource "random_string" "policy_suffix_rand" {
  length  = 8
  special = false
}

locals {
  policy_prefix = "morgan"
}

#
# POLICIES
#
resource "aws_iam_policy" "external_dns_policy" {
  name        = "${local.policy_prefix}-external_dns_policy"
  description = "External DNS policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        "Effect" : "Allow",
        "Action" : [
          "route53:ChangeResourceRecordSets"
        ],
        "Resource" : [
          "arn:aws:route53:::hostedzone/*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "route53:ListHostedZones",
          "route53:ListResourceRecordSets",
          "route53:ListTagsForResource"
        ],
        "Resource" : [
          "*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "ebs_csi_driver_policy" {
  name        = "${local.policy_prefix}-ebs_csi_driver_policy"
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
  name        = "${local.policy_prefix}-external-dns-policy"
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
  name        = "${local.policy_prefix}-sqs-queue-policy"
  description = "AWS SQS queues policy"

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "sqs:DeleteMessage",
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

module "eks_role" {
  source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
 
  role_name = "${local.policy_prefix}-iam-eks-role"
 
  attach_ebs_csi_policy = true
  attach_external_dns_policy = true
  attach_load_balancer_controller_policy = true
 
  oidc_providers = {
    main = {
      provider_arn               = var.oidc_provider
      namespace_service_accounts = ["kube-system:morgan_eks_policy"]
    }
  }
}

module "iam_eks_role_lb_controller" {
  source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  role_name = "${local.policy_prefix}-amazoneks_loadbalancer_controller_role"

  attach_load_balancer_controller_policy = true

  oidc_providers = {
    one = {
      provider_arn               = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${var.oidc_provider}"
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}

data "aws_iam_policy_document" "instance_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${var.oidc_provider}"]
    }
  }
}

resource "aws_iam_role" "external_dns" {
  name = "${local.policy_prefix}-v2-external_dns"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${var.oidc_provider}"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${var.oidc_provider}:aud" = "sts.amazonaws.com",
            "${var.oidc_provider}:sub" = "system:serviceaccount:notification-service-app:external-dns"
          }
        }
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "external_dns_attachment" {
  policy_arn = aws_iam_policy.external_dns_policy.arn
  role       = aws_iam_role.external_dns.name
}


# resource "aws_iam_role" "external_dns_role" {
#   name        = "${local.policy_prefix}-external_dns"
#   description = "External DNS role"

#   assume_role_policy  = data.aws_iam_policy_document.instance_assume_role_policy.json
#   managed_policy_arns = [aws_iam_policy.external_dns_policy.arn]
# }

resource "aws_iam_role" "ebs_csi_role" {
  name        = "${local.policy_prefix}-ebs_csi_role"
  description = "EBS CSI role"

  assume_role_policy  = data.aws_iam_policy_document.instance_assume_role_policy.json
  managed_policy_arns = [aws_iam_policy.ebs_csi_driver_policy.arn]
}

# resource "aws_iam_role" "sqs_role" {
#   name        = "${local.policy_prefix}-sqs_role"
#   description = "SQS role"

#   assume_role_policy  = data.aws_iam_policy_document.instance_assume_role_policy.json
#   managed_policy_arns = [aws_iam_policy.sqs_queue_policy.arn]
# }

resource "aws_iam_role_policy_attachment" "attach_sqs_policy" {
  policy_arn = aws_iam_policy.devops_demo_sqs_policy.arn
  role       = aws_iam_role.sqs_role.name  
}

resource "aws_iam_role" "sqs_role" {
  name = "${local.policy_prefix}-sqs-role" 

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${var.oidc_provider}"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${var.oidc_provider}:sub" = "system:serviceaccount:notification-service-app:${local.policy_prefix}-sqs-role"
          }
        }
      }
    ]
  })
}


resource "aws_iam_policy" "devops_demo_sqs_policy" {
  name        = "devops-demo-sqs-policy"
  description = "Allows sending messages to the priority SQS queues"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:GetQueueUrl",
          "sqs:GetQueueAttributes",
          "sqs:DeleteMessage",
          "sqs:ReceiveMessage"
        ]
        Resource = [
          var.priority_queue_1_url,
          var.priority_queue_2_url,
          var.priority_queue_3_url,
          var.dead_letter_queue_url
        ]
      }
    ]
  })
}

# aws_iam_role_policy_attachement ?

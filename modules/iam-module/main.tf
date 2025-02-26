data "aws_caller_identity" "current" {}

resource "random_string" "policy_prefix" {
  length  = 8
  special = false
}

resource "aws_iam_policy" "external_dns_policy" {
  name        = "${random_string.policy_prefix.id}-external_dns_policy"
  description = "External DNS policy"

  policy = <<EOT
{
    "Version": "2012-10-17",
    "Statement":[
        {
            "Effect":"Allow",
            "Action":[
                "route53:*", 
                "route53domains:*",
                "tag:*"
            ],
            "Resource":"*"
        },
        {
            "Effect": "Allow",
            "Action": "apigateway:GET",
            "Resource": "arn:aws:apigateway:*::/domainnames"
        }
    ]
}
EOT
}

resource "aws_iam_policy" "ebs_csi_driver_policy" {
  name        = "${random_string.policy_prefix.id}-ebs_csi_driver_policy"
  description = "EBS CSI Driver policy"

  policy = <<EOT
{
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": [
            "kms:CreateGrant",
            "kms:ListGrants",
            "kms:RevokeGrant"
          ],
          "Resource": ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${data.aws_caller_identity.current.user_id}"],
          "Condition": {
            "Bool": {
              "kms:GrantIsForAWSResource": "true"
            }
          }
        },
        {
          "Effect": "Allow",
          "Action": [
            "kms:Encrypt",
            "kms:Decrypt",
            "kms:ReEncrypt*",
            "kms:GenerateDataKey*",
            "kms:DescribeKey"
          ],
          "Resource": ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${data.aws_caller_identity.current.user_id}"]
        }
      ]
    }
EOT
}

resource "aws_iam_policy" "ecr_repository_policy" {
  name        = "${random_string.policy_prefix.id}-external-dns-policy"
  description = "AWS ECR repo policy"

  policy = <<EOT
{
    "Version": "2012-10-17",
    "Statement":[
        {
            "Effect":"Allow",
            "Action":[
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
            "Resource": ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${data.aws_caller_identity.current.user_id}"]
        }
    ]
}
EOT
}

resource "aws_iam_policy" "sqs_queue_policy" {
  name        = "${random_string.policy_prefix.id}-sqs-queue-policy"
  description = "AWS SQS queues policy"

  policy = <<EOT
{
    "Version": "2012-10-17",
    "Statement":[
        {
            "Effect":"Allow",
            "Action":[
                "sqs:*"
            ],
            "Resource": ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${data.aws_caller_identity.current.user_id}"]
        }
    ]
}
EOT
}

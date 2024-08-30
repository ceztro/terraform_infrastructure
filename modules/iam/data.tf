data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "kms_policy" {
  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "Allow administration of the key"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/adminuser"]  # Replace with actual EKS administrator ARN
    }
    actions = [
      "kms:ReplicateKey",
      "kms:Create*",
      "kms:Describe*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Get*",
      "kms:Delete*",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "Allow CloudWatch Logs to use the key"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["logs.${var.region}.amazonaws.com"]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = ["*"]
  }
}

##################
## EKS ACCESS     ##
##################


data "aws_iam_policy_document" "eks_admin_policy" {
  statement {
    effect = "Allow"
    actions = [
      "eks:*",
      "ec2:Describe*",
      "iam:ListRoles",
      "iam:GetRole",
      "cloudformation:DescribeStacks",
      "cloudformation:ListStacks",
      "elasticloadbalancing:*",
      "autoscaling:*",
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:DescribeInstanceInformation",
      "ssm:SendCommand",
      "ssm:ListCommands",
      "ssm:GetCommandInvocation",
      "ssm:StartSession",
      "ssm:GetConnectionStatus",
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel",
      "ec2messages:AcknowledgeMessage",
      "ec2messages:DeleteMessage",
      "ec2messages:FailMessage",
      "ec2messages:GetEndpoint",
      "ec2messages:GetMessages",
      "ec2messages:SendReply"
    ]
    resources = ["*"]
  }
}

# data "aws_iam_policy_document" "eks_admin_trust_policy" {
#   statement {
#     effect = "Allow"
#     actions = ["sts:AssumeRole"]

#     principals {
#       type        = "AWS"
#       identifiers = [
#         for user in aws_iam_user.eks_admins : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${user.name}"
#       ]
#     }
#   }
# }

##################
## OIDC     ##
##################

# data "aws_iam_policy_document" "oidc_trust_policy" {
#   statement {
#     actions = ["sts:AssumeRoleWithWebIdentity"]

#     principals {
#       type        = "Federated"
#       identifiers = [aws_iam_openid_connect_provider.this.arn]
#     }

#     condition {
#       test     = "StringEquals"
#       values   = ["sts.amazonaws.com"]
#       variable = "token.actions.githubusercontent.com:aud"
#     }

#     condition {
#       test     = "StringLike"
#       values   = ["repo:ceztro/terraform_infrastructure"]
#       variable = "token.actions.githubusercontent.com:sub"
#     }
#   }
# }

##################
## Github Actions 
##################

# 

data "aws_iam_policy_document" "github_actions_user_policy" {
  statement {
    effect  = "Allow"
    actions = [
      "ec2:StartInstances",
      "ec2:StopInstances",
      "ec2:RebootInstances",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceStatus",
      "ec2:DescribeInstanceAttribute",
      "ec2:TerminateInstances",
      "ec2:ModifyInstanceAttribute"
    ]
    resources = ["arn:aws:ec2:${var.region}:${data.aws_caller_identity.current.account_id}:instance/${var.github_runner_ec2}"]
  }
}

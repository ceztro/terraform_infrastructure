data "aws_caller_identity" "current" {}

##################
## Bastion Host IAM Policies
##################

data "aws_iam_policy_document" "bastion_host_role_policy" {
  statement {
    actions = [
      "ec2:Describe*",
      "eks:Describe*",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "ssm:DescribeInstanceInformation",
      "ssm:SendCommand",
      "ssm:CreateDocument",
      "ssm:UpdateInstanceInformation",
      "ssm:ListCommands",
      "ssm:GetCommandInvocation",
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel",
      "ec2messages:AcknowledgeMessage",
      "ec2messages:DeleteMessage",
      "ec2messages:FailMessage",
      "ec2messages:GetEndpoint",
      "ec2messages:GetMessages",
      "ec2messages:SendReply",
      "ecr:*"
    ]
    effect = "Allow"
    resources = ["*"]
  }

  # Restrict SSM StartSession to specific users
  statement {
    actions = [
      "ssm:StartSession"
    ]
    effect = "Allow"
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalArn"
      values   = flatten([var.eks_admins_arns])
    }
  }
}

data "aws_iam_policy_document" "bastion_host_trust_relationship_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]  # This pattern can be adjusted depending on the specific requirements
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["137112412989"]  # This is the AWS account ID for Amazon Linux AMIs
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]  # Canonical's AWS account ID for official Ubuntu images
}

##################
## Github Runner IAM Policies
##################

data "aws_iam_policy_document" "github_runner_role_policy" {
  statement {
    actions = [
      "ec2:Describe*",
      "eks:Describe*",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "ssm:DescribeInstanceInformation",
      "ssm:SendCommand",
      "ssm:CreateDocument",
      "ssm:UpdateInstanceInformation",
      "ssm:ListCommands",
      "ssm:GetCommandInvocation",
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel",
      "ec2messages:AcknowledgeMessage",
      "ec2messages:DeleteMessage",
      "ec2messages:FailMessage",
      "ec2messages:GetEndpoint",
      "ec2messages:GetMessages",
      "ec2messages:SendReply",
      "ecr:*"
    ]
    effect = "Allow"
    resources = ["*"]
  }

  # Restrict SSM StartSession to specific users
  statement {
    actions = [
      "ssm:StartSession"
    ]
    effect = "Allow"
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalArn"
      values   = flatten([var.eks_admins_arns])
    }
  }

  # Add access to the specific Secrets Manager secret
  statement {
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    effect   = "Allow"
    resources = [
      "arn:aws:secretsmanager:us-east-1:871548798187:secret:github_token_for_actions_runner-2KGVpw"
    ]
  }
}

##################
## Auth ConfigMap file
##################

resource "local_file" "aws_auth_configmap" {
  content  = base64encode(templatefile("${path.module}/resources/aws_auth_configmap.tpl", {
    account_id = data.aws_caller_identity.current.account_id,
    usernames  = flatten(var.eks_admins_names),
  }))
  filename = "${path.module}/resources/aws_auth_configmap.yaml"
}

data "local_file" "argo_cd_application" {
  filename = "./modules/bastion_host/resources/argo_cd_application.yaml"
}

data "local_file" "argo_cd_ignore_configmaps" {
  filename = "./modules/bastion_host/resources/argo_cd_ignore_configmaps.yaml"
}
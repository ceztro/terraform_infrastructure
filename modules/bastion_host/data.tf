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
      "ec2messages:SendReply"
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
      values   = flatten([var.eks_admins])
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

##################
## Auth ConfigMap file
##################

data "local_file" "config_map_aws_auth" {
  filename = "./modules/bastion_host/resources/eks_auth_configmap.yaml"
}

data "local_file" "read_only_role" {
  filename = "./modules/bastion_host/resources/read_only_role.yaml"
}
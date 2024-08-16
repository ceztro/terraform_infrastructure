##################
## EKS Cluster IAM Policies
##################

data "aws_iam_policy_document" "eks_cluster_role_policy" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:CreateTags"
    ]
    resources = [
      "arn:aws:ec2:*:*:instance/*"
    ]
    condition {
      test     = "ForAnyValue:StringLike"
      variable = "aws:TagKeys"
      values   = ["kubernetes.io/cluster/*"]
    }
  }

  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeVpcs",
      "ec2:DescribeDhcpOptions",
      "ec2:DescribeAvailabilityZones",
      "kms:DescribeKey"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "eks_cluster_trust_relationship_policy" {
  statement {
    effect = "Allow"

    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com", "eks.amazonaws.com"]
    }
  }
}

##################
## EKS Nodes IAM Policies
##################

data "aws_iam_policy_document" "eks_node_trust_relationship_policy" {
  statement {
    effect = "Allow"

    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}
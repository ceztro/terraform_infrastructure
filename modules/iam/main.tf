##################
## KMS KEY      ##
##################

resource "aws_kms_key" "eks" {
  description             = "symmetric encryption KMS key for EKS cluster ${var.cluster_name}"
  enable_key_rotation     = true
  deletion_window_in_days = 20
  policy = data.aws_iam_policy_document.kms_policy.json
}

##################
## EKS Admins     ##
##################

resource "aws_iam_user" "eks_admins" {
  for_each = var.eks_admins

  name = each.value

  tags = {
    Role = "EKS Admin"
  }
}

resource "aws_iam_user_policy" "eks_admins_user_policy" {
  for_each = aws_iam_user.eks_admins

  name   = "AssumeEksAdminPolicy-${each.key}"
  user   = each.value.name
  policy = data.aws_iam_policy_document.eks_admin_policy.json
}
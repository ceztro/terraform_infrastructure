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

# resource "aws_iam_role" "eks_admin_role" {
#   name               = "eks-admin-role"
#   assume_role_policy = data.aws_iam_policy_document.eks_admin_trust_policy.json

#   tags = {
#     Role = "EKS Admin"
#   }
# }

# resource "aws_iam_policy" "eks_admin_policy" {
#   name        = "eks-admin-policy"
#   description = "Policy to allow full access to EKS administration and EC2 SSM access"
#   policy      = data.aws_iam_policy_document.eks_admin_policy.json
# }

# resource "aws_iam_role_policy_attachment" "attach_eks_admin_policy" {
#   role       = aws_iam_role.eks_admin_role.name
#   policy_arn = aws_iam_policy.eks_admin_policy.arn
# }

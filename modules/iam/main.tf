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


# ##################
# ## OIDC     ##
# ##################

# resource "aws_iam_openid_connect_provider" "this" {
#   url = "https://token.actions.githubusercontent.com"

#   client_id_list = [
#     "sts.amazonaws.com",
#   ]

#   thumbprint_list = ["ffffffffffffffffffffffffffffffffffffffff"]
# }

# resource "aws_iam_role" "oidc" {
#   name               = "github_oidc_role"
#   assume_role_policy = data.aws_iam_policy_document.oidc_trust_policy.json
# }

# resource "aws_iam_policy" "oidc_role_policy" {
#   name        = "ci-deploy-policy"
#   description = "Policy used for deployments on CI"
#   policy      = data.aws_iam_policy_document.oidc_deploy_policy.json
# }

# resource "aws_iam_role_policy_attachment" "oidc_policy_attachment" {
#   role       = aws_iam_role.oidc.name
#   policy_arn = aws_iam_policy.oidc_role_policy.arn
# }


##################
## Github Actions IAM User
##################

# resource "aws_iam_user" "github_actions_user" {
#   name = "github-actions-user"

#   tags = {
#     Role = "Github Actions"
#   }
# }

# resource "aws_iam_user_policy" "github_actions_user_policy" {
#   name   = "GithubActionsUserPolicy"
#   user   = aws_iam_user.github_actions_user.name
#   policy = data.aws_iam_policy_document.github_actions_user_policy.json
# }

# resource "aws_iam_access_key" "github_actions" {
#   user    = aws_iam_user.github_actions_user.name
# }

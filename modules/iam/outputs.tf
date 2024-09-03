output "kms_eks_key_arn" {
  value = aws_kms_key.eks.arn
}

output "usernames" {
  value = [for user in aws_iam_user.eks_admins : user.name]
}

##################
## Github Actions IAM User Access Keys
##################

# output "github_actions_access_key_id" {
#   value = aws_iam_access_key.github_actions.id
# }

# output "github_actions_secret_access_key" {
#   value       = aws_iam_access_key.github_actions.secret
#   description = "This is the secret access key for the GitHub Actions IAM user"
#   sensitive   = true
# }
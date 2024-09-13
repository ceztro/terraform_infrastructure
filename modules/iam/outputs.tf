output "kms_eks_key_arn" {
  value = aws_kms_key.eks.arn
}

output "usernames" {
  value = [for user in aws_iam_user.eks_admins : user.name]
}

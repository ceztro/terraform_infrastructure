##################
## KMS KEY      ##
##################

resource "aws_kms_key" "eks" {
  description             = "symmetric encryption KMS key for EKS cluster ${var.cluster_name}"
  enable_key_rotation     = true
  deletion_window_in_days = 20
  policy = data.aws_iam_policy_document.kms_policy.json
}
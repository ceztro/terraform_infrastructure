provider "aws" {
  region = var.region
  assume_role {
    role_arn     = var.aws_iam_role
    session_name = "terraform_session"
  }
}
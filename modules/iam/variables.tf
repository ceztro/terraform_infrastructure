variable cluster_name {
  description = "The name of the EKS cluster"
  type        = string
}

variable region {
  description = "The AWS region"
  type        = string
}

variable github_runner_ec2 {
  description = "The name of the EC2 instance that will be used as a GitHub Actions runner"
  type        = string
}
variable my_ip {
  description = "Your IP address for SSH access"
  type        = string
}

variable env {
  description = "The environment in which the infrastructure is being deployed"
  type        = string
}

variable project_name {
  description = "The name of the project"
  type        = string
}

variable project_tags {
  description = "Tags to apply to all resources"
  type        = map(string)
}

variable region {
  description = "The AWS region in which the infrastructure is being deployed"
  type        = string
}

variable vpc_id {
  description = "The ID of the VPC in which the resources are being deployed"
  type        = string
}

variable public_subnet_id {
  description = "The ID of the public subnets in which the bastion host is being deployed"
  type        = string
}

variable ssh_pub_key_location {
  description = "The location of the public key to be used for SSH access"
  type        = string
}

variable cluster_name {
  description = "The name of the EKS cluster"
  type        = string
}

variable bastion_host {
  description = "The name of the bastion host"
  type        = string
}

variable eks_admins {
  description = "The ARNs of the IAM users who are EKS admins"
  type        = list(string)
}

variable eks_cluster_name {
  description = "The name of the EKS cluster"
  type        = string
}
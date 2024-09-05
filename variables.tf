# project related variables
variable env {
    description = "The environment in which the infrastructure is being deployed"
    type = string
}
variable project_name {
    description = "The name of the project"
    type = string
}
variable project_tags {
    description = "Tags to apply to all resources"
    type = map(string)
}
variable region {
    description = "The AWS region in which the infrastructure is being deployed"
    type = string
} 

variable aws_iam_role {
    description = "The IAM role for the resources in the project"
    type = string
}

# networking variables
variable cidr_block {
    description = "The CIDR block for the VPC"
    type = string
}
variable public_subnets {
    description = "The CIDR blocks for the public subnets"
    type = list(string)
}
variable private_subnets {
    description = "The CIDR blocks for the private subnets"
    type = list(string)
}
variable instance_tenancy {
    description = "The tenancy of the instances"
    type = string
}

# cluster variables
variable cluster_name {
    description = "The name of the EKS cluster"
    type = string
}
variable endpoint_private_access {
    description = "Whether or not the EKS cluster has private access"
    type = bool
}
variable endpoint_public_access {
    description = "Whether or not the EKS cluster has public access"
    type = bool
}

# node group variables
variable instance_types {
    description = "The instance types for the EKS node group"
    type = list(string)
}
variable pvt_desired_size {
    description = "The desired size of the private node group"
    type = number
}
variable pvt_max_size {
    description = "The maximum size of the private node group"
    type = number
}
variable pvt_min_size {
    description = "The minimum size of the private node group"
    type = number
}

# rds variables
variable rds_username {
    description = "The username for the RDS instance"
    type = string
}

# bastion host variables
variable my_ip {
    description = "Your IP address for SSH access"
    type = string
}
variable public_key {
    description = "The public key to use for SSH access"
    type = string
}
variable bastion_host {
    description = "The name of the bastion host"
    type = string
}
variable github_account_repo {
    description = "The name of the GitHub repository"
    type = string
}
variable github_account_org {
    description = "The name of the GitHub organization"
    type = string
}
variable db_name {
    description = "The name of the RDS database"
    type = string
}

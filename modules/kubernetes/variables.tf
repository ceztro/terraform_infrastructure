# EKS Cluster Variables
variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
}

variable "kms_key_arn" {
  description = "The ARN of the KMS key"
  type        = string
}

variable "eks_cluster_subnet_ids" {
  description = "A list of subnet IDs for the EKS cluster"
  type        = list(string)
}

variable "endpoint_private_access" {
  description = "Indicates whether or not the Amazon EKS private API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Indicates whether or not the Amazon EKS public API server endpoint is enabled"
  type        = bool
  default     = false
}

variable bastion_host_security_group_id {
  description = "The ID of the security group for the Bastion host"
  type        = string
}

variable namespace {
  description = "The namespace for the service account"
  type        = string
}

variable service_account_name {
  description = "The name of the service account"
  type        = string
}

# Project variables
variable "env" {
  description = "The environment for the EKS cluster (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "region" {
  description = "The AWS region where the EKS cluster will be created"
  type        = string
  default     = "us-west-2"
}

variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "project_tags" {
  description = "A map of tags to assign to resources"
  type        = map(string)
  default     = {}
}

variable "aws_iam_role" {
  description = "The IAM role for the EKS cluster"
  type        = string
}

# Node group variables
variable "ami_type" {
  description = "The AMI type for the node group (e.g., AL2_x86_64, AL2_x86_64_GPU)"
  type        = string
  default     = "AL2_x86_64"
}

variable "disk_size" {
  description = "The disk size in GB for the node group"
  type        = number
  default     = 20
}

variable "instance_types" {
  description = "A list of instance types for the node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "pvt_desired_size" {
  description = "The desired number of private nodes"
  type        = number
  default     = 2
}

variable "pvt_max_size" {
  description = "The maximum number of private nodes"
  type        = number
  default     = 3
}

variable "pvt_min_size" {
  description = "The minimum number of private nodes"
  type        = number
  default     = 1
}

# Outsourced variables
variable "private_subnets" {
  description = "A list of private subnet IDs"
  type        = list(string)
}

variable "public_subnets" {
  description = "A list of public subnet IDs"
  type        = list(string)
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}
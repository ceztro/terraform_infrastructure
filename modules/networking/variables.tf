# Project related variables
variable "env" {
  description = "The environment in which the infrastructure is being deployed (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
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

variable "region" {
  description = "The AWS region where the infrastructure will be deployed"
  type        = string
  default     = "us-west-1"
}

# Networking variables
variable "cidr_block" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "A list of public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets" {
  description = "A list of private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "instance_tenancy" {
  description = "The instance tenancy attribute for the VPC (e.g., default, dedicated)"
  type        = string
  default     = "default"
}
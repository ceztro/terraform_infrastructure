##################
## Project variables
##################

variable project_name {
    description = "The name of the project"
    type = string
}

variable env {
    description = "The environment in which the infrastructure is being deployed"
    type = string
}
variable region {
    description = "The region in which the infrastructure is being deployed"
    type = string
}

variable project_tags {
    description = "The tags to apply to all resources"
    type = map(string)
}

variable aws_iam_role {
    description = "The IAM role for the RDS instance"
    type = string
}

##################
## Module variables
##################

variable private_subnet_id {
    description = "The ID of the private subnet"
    type = string
}

variable instance_class {
    description = "The instance class for the RDS instance"
    type = string
    default = "db.t3.micro"
}

variable engine {
    description = "The engine for the RDS instance"
    type = string
    default = "postgres"
}

variable rds_username {
    description = "The username for the RDS instance"
    type = string
}

variable rds_password {
    description = "The password for the RDS instance"
    type = string
}

variable vpc_cidr {
    description = "The CIDR block for the VPC"
    type = string
}

variable vpc_id {
    description = "The ID of the VPC"
    type = string
}

variable kms_key_arn {
    description = "The ARN of the KMS key"
    type = string
}
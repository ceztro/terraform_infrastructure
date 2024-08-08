# project related variables
variable env {
    description = "The environment in which the infrastructure is being deployed"
    type = string
}
variable project_name {}
variable project_tags {}
variable region {} 

# networking variables
variable cidr_block {}
variable public_subnets {}
variable private_subnets {}
variable dns_hostnames {}
variable instance_tenancy {}
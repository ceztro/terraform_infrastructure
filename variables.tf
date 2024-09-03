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
variable instance_tenancy {}

# cluster variables
variable cluster_name {}
variable endpoint_private_access {}
variable endpoint_public_access {}

# node group variables
variable node_group_name {}
variable instance_types {}
variable pvt_desired_size {}
variable pvt_max_size {}
variable pvt_min_size {}
variable pblc_desired_size {}
variable pblc_max_size {}
variable pblc_min_size {}

# bastion host variables
variable my_ip {}
variable ssh_pub_key_location {}
variable bastion_host {}
variable github_account_repo {}
variable github_account_org {}

#shared variables
region           = "us-east-1"
env              = "dev"
project_name     = "travel-guide"
project_tags     = { "Project Name" = "travel guide", "Project Owner" = "Cezary Trojanowski", "Deployment Type" = "terraform"}

#networking variables
cidr_block       = "10.0.0.0/16"
public_subnets   = ["10.0.32.0/19", "10.0.64.0/19"]
private_subnets  = ["10.0.96.0/19", "10.0.128.0/19"]
instance_tenancy = "default"

# cluster variables
cluster_name            = "travel-guide-eks-cluster"
endpoint_private_access = true
endpoint_public_access  = false  # < must be set to true in order to deploy CI/CD that will deploy to the cluster

# node group variables
instance_types = ["t3.medium"]
pvt_desired_size = 2
pvt_max_size  = 2
pvt_min_size  = 1
pblc_desired_size = 2 
pblc_max_size = 2
pblc_min_size = 1

# bastion host variables
bastion_host = "bastion-host"
github_account_repo = "travel_guide"
github_account_org = "ceztro"
provider "aws" {
}

module "networking" {
  source = "./modules/networking/"

  #shared variables
  region           = var.region
  env              = var.env
  project_name     = var.project_name
  project_tags     = var.project_tags
  
  #networking variables
  cidr_block       = var.cidr_block
  public_subnets   = var.public_subnets
  private_subnets  = var.private_subnets
  instance_tenancy = var.instance_tenancy
}

module "kubernetes" {
  source = "./modules/kubernetes/"

  # EKS Cluster Variables
  cluster_name                = var.cluster_name
  kms_key_arn                 = module.iam.kms_eks_key_arn
  eks_cluster_subnet_ids      = flatten([module.networking.public_subnets, module.networking.private_subnets])
  endpoint_private_access     = var.endpoint_private_access
  endpoint_public_access      = var.endpoint_public_access

  # Project variables
  env                         = var.env
  region                      = var.region
  project_name                = var.project_name
  project_tags                = var.project_tags

  # Node group variables
  node_group_name             = var.node_group_name
  instance_types              = var.instance_types
  pvt_desired_size            = var.pvt_desired_size
  pvt_max_size                = var.pvt_max_size
  pvt_min_size                = var.pvt_min_size
  pblc_desired_size           = var.pblc_desired_size
  pblc_max_size               = var.pblc_max_size
  pblc_min_size               = var.pblc_min_size

  # Outsourced variables
  private_subnets             = module.networking.private_subnets
  public_subnets              = module.networking.public_subnets
  vpc_id                      = module.networking.vpc_id
}

module "iam" {
  source = "./modules/iam/"

  cluster_name = var.cluster_name
  region       = var.region
}
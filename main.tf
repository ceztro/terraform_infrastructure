module "networking" {
  source = "./modules/networking/"
  aws_iam_role    = var.aws_iam_role


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
  aws_iam_role    = var.aws_iam_role

  # EKS Cluster Variables
  cluster_name                = var.cluster_name
  kms_key_arn                 = module.iam.kms_eks_key_arn
  eks_cluster_subnet_ids      = [module.networking.private_subnets[0], module.networking.private_subnets[1]]
  endpoint_private_access     = var.endpoint_private_access
  endpoint_public_access      = var.endpoint_public_access
  bastion_host_security_group_id = module.bastion_host.bastion_host_security_group_id
  namespace                   = var.namespace
  service_account_name        = var.service_account_name
  alb_controller_service_account_name = var.alb_controller_service_account_name
  prometheus_namespace       = var.prometheus_namespace
  prometheus_service_account = var.prometheus_service_account
  ebs_csi_service_account    = var.ebs_csi_service_account

  # Project variables
  env                         = var.env
  region                      = var.region
  project_name                = var.project_name
  project_tags                = var.project_tags

  # Node group variables
  instance_types              = var.instance_types
  pvt_desired_size            = var.pvt_desired_size
  pvt_max_size                = var.pvt_max_size
  pvt_min_size                = var.pvt_min_size

  # Outsourced variables
  private_subnets             = module.networking.private_subnets
  public_subnets              = module.networking.public_subnets
  vpc_id                      = module.networking.vpc_id
}

module "rds" {
  source = "./modules/rds/"
  aws_iam_role    = var.aws_iam_role

  #shared variables
  region           = var.region
  env              = var.env
  project_name     = var.project_name
  project_tags     = var.project_tags

  # RDS variables
  vpc_id            = module.networking.vpc_id
  vpc_cidr          = module.networking.vpc_cidr
  private_subnet_ids = module.networking.private_subnets
  rds_username      = var.rds_username
  kms_key_arn       = module.iam.kms_eks_key_arn
  db_name           = var.db_name
  db_identifier     = var.db_identifier
}

module "iam" {
  source = "./modules/iam/"
  aws_iam_role    = var.aws_iam_role

  cluster_name      = var.cluster_name
  region            = var.region
  github_runner_ec2 = module.bastion_host.github_runner_ec2_id
}

module "bastion_host" {
  source = "./modules/bastion_host/"
  aws_iam_role    = var.aws_iam_role

  my_ip                  = var.my_ip
  vpc_id                 = module.networking.vpc_id
  public_key             = var.public_key
  cluster_name           = var.cluster_name
  bastion_host           = var.bastion_host
  eks_admins_arns        = [for user in module.iam.usernames : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${user}"]
  eks_admins_names       = module.iam.usernames
  github_account_repo    = var.github_account_repo
  github_account_org     = var.github_account_org
  eks_cluster_name       = module.kubernetes.eks_cluster_name
  alb_controller_service_account_name = var.alb_controller_service_account_name

  #shared variables
  region           = var.region
  env              = var.env
  project_name     = var.project_name
  project_tags     = var.project_tags
  public_subnet_id = module.networking.public_subnets[0]
}
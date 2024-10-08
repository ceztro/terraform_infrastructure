##################
## EKS Cluster ##
##################

resource "aws_eks_cluster" "this" {
    name = var.cluster_name
    role_arn = aws_iam_role.eks_cluster_role.arn

    vpc_config {
        subnet_ids = var.eks_cluster_subnet_ids
        security_group_ids = [aws_security_group.eks_cluster.id]
        endpoint_private_access = var.endpoint_private_access
        endpoint_public_access = var.endpoint_public_access
    }

    encryption_config {
    provider {
      key_arn = var.kms_key_arn
    }
    resources = ["secrets"]
    }

    enabled_cluster_log_types = ["api"]

    depends_on = [
        aws_iam_role_policy_attachment.eks_cluster_role_policy_attachment,
        aws_iam_role.eks_cluster_role
    ]

    tags = merge(
      { "Env" = var.env, "Name" = "${var.project_name}-eks-cluster" },
      var.project_tags
    )
}

##################
## OIDC
##################

resource "aws_iam_openid_connect_provider" "this" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.external.fetch_thumbprint.result.thumbprint]
  url             = data.aws_eks_cluster.this.identity.0.oidc.0.issuer           
}

resource "aws_iam_role" "pod_role" {
  name               = "pod-role"
  assume_role_policy = data.aws_iam_policy_document.pod_role_trust_relationship.json
}

resource "aws_iam_policy" "pod_role_policy" {
  name   = "pod-role-policy"
  policy = data.aws_iam_policy_document.pod_policy.json
}

resource "aws_iam_role_policy_attachment" "attach_pod_policy" {
  role       = aws_iam_role.pod_role.name
  policy_arn = aws_iam_policy.pod_role_policy.arn
}

##################
## K8s ALB Role
##################

resource "aws_iam_role" "k8s_alb_role" {
  name               = "k8s_alb_role"
  assume_role_policy = data.aws_iam_policy_document.alb_controller_trust_relationship.json
}

resource "aws_iam_policy" "k8s_alb_role_policy" {
  name   = "k8s_alb_role_policy"
  policy = data.aws_iam_policy_document.alb_controller_policy.json
}

resource "aws_iam_role_policy_attachment" "attach_k8s_alb_policy" {
  role       = aws_iam_role.k8s_alb_role.name
  policy_arn = aws_iam_policy.k8s_alb_role_policy.arn
}

##################
## K8s Prometheus Role
##################

resource "aws_iam_role" "k8s_prometheus_role" {
  name               = "k8s_prometheus_role"
  assume_role_policy = data.aws_iam_policy_document.prometheus_role_trust_relationship.json
}

resource "aws_iam_policy" "k8s_prometheus_role_policy" {
  name   = "k8s_prometheus_role_policy"
  policy = data.aws_iam_policy_document.prometheus_policy.json
}

resource "aws_iam_role_policy_attachment" "attach_k8s_prometheus_role_policy" {
  role       = aws_iam_role.k8s_prometheus_role.name
  policy_arn = aws_iam_policy.k8s_prometheus_role_policy.arn
}

##################
## EBS CSI Controller Role
##################

resource "aws_iam_role" "ebs_csi_role" {
  name               = "ebs_csi_role"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_role_trust_relationship.json
}

resource "aws_iam_policy" "ebs_csi_role_policy" {
  name   = "ebs_csi_role_policy"
  policy = data.aws_iam_policy_document.ebs_csi_policy.json
}

resource "aws_iam_role_policy_attachment" "attach_ebs_csi_role_policy" {
  role       = aws_iam_role.ebs_csi_role.name
  policy_arn = aws_iam_policy.ebs_csi_role_policy.arn
}

##################
## EKS Cluster IAM ROLE
##################

resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.cluster_name}-eks-cluster-role"

  assume_role_policy = data.aws_iam_policy_document.eks_cluster_trust_relationship_policy.json
}

resource "aws_iam_policy" "eks_cluster_role_policy" {
  name        = "${var.cluster_name}-eks-cluster-role-policy"
  description = "A policy that allows EC2 tagging and various describe actions."

  policy = data.aws_iam_policy_document.eks_cluster_role_policy.json
}

resource "aws_iam_role_policy_attachment" "eks_cluster_role_policy_attachment" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = aws_iam_policy.eks_cluster_role_policy.arn
}

##################
## EKS Cluster Security Group
##################

resource "aws_security_group" "eks_cluster" {
  name        = "${var.cluster_name}-eks-cluster-sg"
  description = "Cluster communication with worker nodes"
  vpc_id      = var.vpc_id

  tags = merge(
    { "Env" = var.env, "Name" = "${var.project_name}-eks-cluster-sg" },
    var.project_tags
  )
}

resource "aws_security_group_rule" "cluster_inbound" {
  description              = "Allow worker nodes to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster.id
  source_security_group_id = aws_security_group.eks_nodes.id
  to_port                  = 443
  type                     = "ingress"
}

resource "aws_security_group_rule" "cluster_inbound_bastion_host" {
  description              = "Allow bastion host to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster.id
  source_security_group_id = var.bastion_host_security_group_id
  to_port                  = 443
  type                     = "ingress"
}

resource "aws_security_group_rule" "cluster_outbound" {
  description              = "Allow cluster API Server to communicate with the worker nodes"
  from_port                = 1024
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster.id
  source_security_group_id = aws_security_group.eks_nodes.id
  to_port                  = 65535
  type                     = "egress"
}

##################
## EKS Cluster Node Groups
##################

# Nodes in private subnets
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.project_name}-eks-node-group"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = var.private_subnets

  ami_type       = var.ami_type
  disk_size      = var.disk_size
  instance_types = var.instance_types

  scaling_config {
    desired_size = var.pvt_desired_size
    max_size     = var.pvt_max_size
    min_size     = var.pvt_min_size
  }

  tags = merge(
    { "Env" = var.env, "Name" = "${var.project_name}-eks-cluster-node-group" },
    var.project_tags
  )

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.aws_eks_worker_node_policy,
    aws_iam_role_policy_attachment.aws_eks_cni_policy,
    aws_iam_role_policy_attachment.ec2_read_only,
  ]
}

##################
## EKS Node IAM Role
##################

resource "aws_iam_role" "eks_nodes" {
  name                 = "${var.cluster_name}-worker-role"

  assume_role_policy = data.aws_iam_policy_document.eks_node_trust_relationship_policy.json
}

resource "aws_iam_role_policy_attachment" "aws_eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "aws_eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "ec2_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_nodes.name
}

##################
## EKS Node Security Group
##################

resource "aws_security_group" "eks_nodes" {
  name        = "${var.project_name}-eks-nodes-sg"
  description = "Security group for all nodes in the cluster"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    { "Env" = var.env, "Name" = "${var.project_name}-eks-nodes-sg" },
    var.project_tags
  )
}

resource "aws_security_group_rule" "nodes" {
  description              = "Allow nodes to communicate with each other"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.eks_nodes.id
  source_security_group_id = aws_security_group.eks_nodes.id
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "nodes_inbound" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_nodes.id
  source_security_group_id = aws_security_group.eks_cluster.id
  to_port                  = 65535
  type                     = "ingress"
}

##################
## EKS Cluster CloudWatch Logging
##################

# Cloudwatch group is not being deleted on destroy, hence I commented it out

# resource "aws_cloudwatch_log_group" "eks" {
#   # The log group name format is /aws/eks/<cluster-name>/cluster
#   # Reference: https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html
#   name              = "/aws/eks/${var.cluster_name}/cluster"
#   retention_in_days = 7
#   kms_key_id        = var.kms_key_arn

#   tags = merge(
#     { "Env" = var.env, "Name" = "${var.project_name}-eks-cluster-sg" },
#     var.project_tags
#   )
# }
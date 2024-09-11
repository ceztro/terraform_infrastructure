# determine how many subnets we want to create
# needed for further deployments

locals {
  len_public_subnets = length(var.public_subnets)
}

locals {
  len_private_subnets = length(var.private_subnets)
}

##################
## VPC
##################

resource "aws_vpc" "this" {
  cidr_block       = var.cidr_block
  instance_tenancy     = var.instance_tenancy

  # These are set to true because otherwise the worker nodes won't be able to join the cluster
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = merge(
    { "Env" = var.env, "Name" = "${var.project_name}-vpc" },
    var.project_tags
  )
}

##################
## PUBLIC SUBNETS
##################

locals {
  create_public_subnets = local.len_public_subnets > 0
}

resource "aws_subnet" "public" {
  count = local.create_public_subnets ? local.len_public_subnets : 0

  vpc_id                  = aws_vpc.this.id
  cidr_block              = element(var.public_subnets, count.index)
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)
  map_public_ip_on_launch = true #because we create here public subnets

  tags = merge(
    { "Env" = var.env, "Name" = "${var.project_name}-public-subnet-${count.index}", "kubernetes.io/role/elb" = "1" },
    var.project_tags
  )
}

resource "aws_route_table" "public" {
  count = local.create_public_subnets ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = merge(
    { "Env" = var.env, "Name" = "${var.project_name}-public-rt" },
    var.project_tags
  )
}

resource "aws_route_table_association" "public" {
  count = local.create_public_subnets ? local.len_public_subnets : 0

  subnet_id      = element(aws_subnet.public[*].id, count.index)
  route_table_id = aws_route_table.public[0].id
}

resource "aws_internet_gateway" "this" {
  count = local.create_public_subnets ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = merge(
    { "Env" = var.env, "Name" = "${var.project_name}-igw" },
    var.project_tags
  )
}

resource "aws_route" "public_internet_gateway" {
  count = local.create_public_subnets ? 1 : 0

  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id

  timeouts {
    create = "5m"
  }
}

resource "aws_eip" "nat" {
  count = local.create_public_subnets ? 1 : 0

  domain = "vpc"

  tags = merge(
    { "Env" = var.env, "Name" = "${var.project_name}-eip" },
    var.project_tags
  )
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat[0].id
  count = local.create_public_subnets ? 1 : 0
  subnet_id     = aws_subnet.public[0].id

  tags = merge(
    { "Env" = var.env, "Name" = "${var.project_name}-natgw" },
    var.project_tags
  )

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.this]
}

##################
## PRIVATE SUBNETS
##################

resource "aws_subnet" "private" {
  count = local.len_private_subnets

  vpc_id                  = aws_vpc.this.id
  cidr_block              = element(var.private_subnets, count.index)
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)
  map_public_ip_on_launch = false #because we create private subnets

  tags = merge(
    { "Env" = var.env, "Name" = "${var.project_name}-private-subnet-${count.index}" },
    var.project_tags
  )
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    { "Env" = var.env, "Name" = "${var.project_name}-private-rt" },
    var.project_tags
  )
}

resource "aws_route_table_association" "private" {
  count = local.len_private_subnets

  subnet_id      = element(aws_subnet.private[*].id, count.index)
  route_table_id = aws_route_table.private.id
}

resource "aws_route" "nat_gateway" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id             = aws_nat_gateway.this[0].id

  timeouts {
    create = "5m"
  }
}

##################
## SECURITY GROUP FOR PUBLIC RESOURCES
##################

resource "aws_security_group" "public_sg" {
  name   = "public-sg"
  vpc_id = aws_vpc.this.id

  tags = merge(
    { "Env" = var.env, "Name" = "${var.project_name}-public-sg" },
    var.project_tags
  )
}

# Security group traffic rules
## Ingress rule
resource "aws_security_group_rule" "sg_ingress_public_443" {
  security_group_id = aws_security_group.public_sg.id
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "sg_ingress_public_80" {
  security_group_id = aws_security_group.public_sg.id
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

## Egress rule
resource "aws_security_group_rule" "sg_egress_public" {
  security_group_id = aws_security_group.public_sg.id
  type              = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}

##################
## SECURITY GROUP FOR DATA PLANE
##################

resource "aws_security_group" "data_plane_sg" {
  name   = "k8s-data-plane-sg"
  vpc_id = aws_vpc.this.id

  tags = merge(
    { "Env" = var.env, "Name" = "${var.project_name}-data-plane-sg" },
    var.project_tags
  )
}

# Security group traffic rules
## Ingress rule
resource "aws_security_group_rule" "nodes" {
  description              = "Allow nodes to communicate with each other"
  security_group_id = aws_security_group.data_plane_sg.id
  type              = "ingress"
  from_port   = 0
  to_port     = 65535
  protocol    = "-1"
  cidr_blocks = flatten([var.public_subnets, var.private_subnets])
}

resource "aws_security_group_rule" "nodes_inbound" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  security_group_id = aws_security_group.data_plane_sg.id
  type              = "ingress"
  from_port   = 1025
  to_port     = 65535
  protocol    = "tcp"
  cidr_blocks = flatten([var.private_subnets])
}

## Egress rule
resource "aws_security_group_rule" "node_outbound" {
  security_group_id = aws_security_group.data_plane_sg.id
  type              = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}

##################
## SECURITY GROUP FOR CONTROL PLANE
##################

resource "aws_security_group" "control_plane_sg" {
  name   = "k8s-control-plane-sg"
  vpc_id = aws_vpc.this.id

  tags = merge(
    { "Env" = var.env, "Name" = "${var.project_name}-control-plane-sg" },
    var.project_tags
  )
}

# Security group traffic rules
## Ingress rule
resource "aws_security_group_rule" "control_plane_inbound" {
  security_group_id = aws_security_group.control_plane_sg.id
  type              = "ingress"
  from_port   = 0
  to_port     = 65535
  protocol          = "tcp"
  cidr_blocks = flatten([var.public_subnets, var.private_subnets])
}

## Egress rule
resource "aws_security_group_rule" "control_plane_outbound" {
  security_group_id = aws_security_group.control_plane_sg.id
  type              = "egress"
  from_port   = 0
  to_port     = 65535
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}

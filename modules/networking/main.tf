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
  enable_dns_hostnames = var.dns_hostnames
  instance_tenancy     = var.instance_tenancy

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
    { "Env" = var.env, "Name" = "${var.project_name}-public-subnet-${count.index}" },
    var.project_tags
  )
}

resource "aws_route_table" "public" {
  count = local.create_public_subnets ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = merge(
    { "Env" = var.env, "Name" = "${var.project_name}-public-rt-${count.index}" },
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

resource "aws_nat_gateway" "this" {
  #might be needed later, if we would like to make public connectivity <<<<<<<<<<<
  #allocation_id = aws_eip.example.id
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
    { "Env" = var.env, "Name" = "${var.project_name}-private-rt-${count.index}" },
    var.project_tags
  )
}

resource "aws_route_table_association" "private" {
  count = local.len_private_subnets

  subnet_id      = element(aws_subnet.private[*].id, count.index)
  route_table_id = aws_route_table.private[0].id
}

resource "aws_route" "nat_gateway" {
  route_table_id         = aws_route_table.private[0].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id             = aws_nat_gateway.this[0].id

  timeouts {
    create = "5m"
  }
}

##################
## SECURITY GROUPS
##################

resource "aws_security_group" "this" {
  name        = "${var.project_name}-sg"
  description = "Allows HTTP for our ECS cluster"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = var.sg_ingress_description
    from_port   = var.sg_ingress_from_port
    to_port     = var.sg_ingress_to_port
    protocol    = "tcp"
    cidr_blocks = var.sg_ingress_cidr
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(
    { "Env" = var.env, "Name" = "${var.project_name}-sg" },
    var.project_tags
  )
}

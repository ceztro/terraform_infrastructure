##################
## RDS          ##
##################

resource "aws_db_instance" "rds" {
  allocated_storage               = 20
  engine                          = var.engine
  instance_class                  = var.instance_class
  db_name                         = "${var.project_name}-rds"
  username                        = var.rds_username
  password                        = var.rds_password
  master_user_secret_kms_key_id   = var.kms_key_arn
  vpc_security_group_ids          = [aws_security_group.rds_sg.id]
  db_subnet_group_name            = aws_db_subnet_group.rds_subnet_group.name
  skip_final_snapshot             = true

  tags = merge(
    { "Env" = var.env, "Name" = "${var.project_name}-rds" },
    var.project_tags
  )
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "${var.project_name}-rds_subnet_group"
  subnet_ids = [var.private_subnet_id]
}

resource "aws_security_group" "rds_sg" {
  vpc_id = var.vpc_id
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
locals {
  all_tags = merge(
    { 
      "Env" = var.env, 
      "Name" = "${var.project_name}-${var.bastion_host}"
    },
    var.project_tags
  )
}

resource "aws_iam_role" "bastion_host" {
  name = "${var.bastion_host}-role"

  assume_role_policy = data.aws_iam_policy_document.bastion_host_trust_relationship_policy.json
}

resource "aws_iam_role_policy" "bastion_host_policy" {
  name = "${var.bastion_host}-policy"
  role = aws_iam_role.bastion_host.id

  policy = data.aws_iam_policy_document.bastion_host_role_policy.json
}

resource "aws_iam_instance_profile" "bastion_host" {
  name = "${var.bastion_host}-profile"
  role = aws_iam_role.bastion_host.name
}

resource "aws_security_group" "bastion_host" {
  name        = "${var.bastion_host}-sg"
  description = "Security group for Bastion Host"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip] # Adjust this to your IP range for SSH access
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "random_id" "lc_id" {
  byte_length = 8
  keepers = {
    timestamp = timestamp()
  }
}

resource "aws_launch_configuration" "bastion_host" {
  depends_on = [
    aws_instance.eks_admin_host,
    var.eks_cluster_name
  ]
  name          = "${var.bastion_host}-config-${formatdate("YYYYMMDDHHmmss", timestamp())}-${random_id.lc_id.hex}"# Ensures uniqueness
  image_id      = data.aws_ami.amazon_linux.id  # Uses a data source to fetch the latest Amazon Linux AMI
  instance_type = "t3.micro"
  security_groups = [aws_security_group.bastion_host.id]
  iam_instance_profile = aws_iam_instance_profile.bastion_host.name
  key_name      = aws_key_pair.deployer.key_name  # Assumes you have already created and imported this key into AWS

  user_data = <<-EOF
    #!/bin/bash
    # Update and install necessary tools
    yum update
    yum install -y git docker jq
    
    # Add the default user to the Docker group
    usermod -aG docker ec2-user

    # Install kubectl to interact with Kubernetes
    curl -o kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/1.18.9/2020-11-02/bin/linux/amd64/kubectl
    chmod +x ./kubectl
    mv ./kubectl /usr/local/bin/kubectl

    # Switch from root to ec2-user and fetching kubeconfig
    su - ec2-user -c "aws eks update-kubeconfig --region ${var.region} --name ${var.cluster_name}"

  EOF

  lifecycle {
    create_before_destroy = true
  }
}



resource "aws_autoscaling_group" "bastion_host" {
  launch_configuration = aws_launch_configuration.bastion_host.id
  min_size             = 1
  max_size             = 1
  desired_capacity     = 1

  vpc_zone_identifier = [var.public_subnet_id]

  tag {
    key                 = "Name"
    value               = var.bastion_host
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = local.all_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = file(var.ssh_pub_key_location)  # Adjust the path to your public key file
}

resource "aws_instance" "eks_admin_host" {
  depends_on = [var.eks_cluster_name]

  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  subnet_id = var.public_subnet_id

  # You can use an existing key pair, or create a new one
  key_name = aws_key_pair.deployer.key_name

  iam_instance_profile = aws_iam_instance_profile.ec2_admin_instance_profile.name

  # Replace with your security group ID
  vpc_security_group_ids = [aws_security_group.bastion_host.id]

  # User data to run commands on instance start
  user_data = <<-EOF
      #!/bin/bash
      # Update and install necessary tools
      yum update
      yum install -y git docker jq
      
      # Add the default user to the Docker group
      usermod -aG docker ec2-user

      # Install kubectl to interact with Kubernetes
      curl -o kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/1.18.9/2020-11-02/bin/linux/amd64/kubectl
      chmod +x ./kubectl
      mv ./kubectl /usr/local/bin/kubectl

      # Decode and save the Kubernetes YAML file
      echo '${data.local_file.read_only_role.content_base64}' | base64 --decode > /tmp/read_only_role.yaml
      echo '${data.local_file.config_map_aws_auth.content_base64}' | base64 --decode > /tmp/configmap.yaml

      # Switch from root to ec2-user and fetching kubeconfig
      su - ec2-user -c "aws eks update-kubeconfig --region ${var.region} --name ${var.cluster_name}"

      # Apply the Kubernetes configuration
      su - ec2-user -c "kubectl apply -f /tmp/read_only_role.yaml"
      su - ec2-user -c "kubectl apply -f /tmp/configmap.yaml"
    EOF

  # Optional: Set a tag to easily identify the instance
  tags = {
    Name = "EksAdminHostInstance"
  }
}

resource "aws_iam_instance_profile" "ec2_admin_instance_profile" {
  name = "ec2_admin_instance_profile"
  role = "terraform-role"
}




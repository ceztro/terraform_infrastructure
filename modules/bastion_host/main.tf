locals {
  all_tags = merge(
    { 
      "Env" = var.env, 
      "Name" = "${var.project_name}-${var.bastion_host}"
    },
    var.project_tags
  )
}

##################
## Bastion Host for Admins
##################

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

    echo 'export PATH=$PATH:/usr/local/bin' >> /home/ec2-user/.bashrc
    echo 'alias k=kubectl' >> /home/ec2-user/.bashrc

    curl -L https://github.com/99designs/aws-vault/releases/latest/download/aws-vault-linux-amd64 -o aws-vault
    chmod +x aws-vault
    mv aws-vault /usr/local/bin/
    echo 'export AWS_VAULT_BACKEND=file' >> /home/ec2-user/.bashrc
    echo 'export AWS_REGION=us-east-1' >> /home/ec2-user/.bashrc

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
  public_key = var.public_key  # Adjust the path to your public key file
}

##################
## Admin Host
##################

resource "aws_instance" "eks_admin_host" {
  depends_on = [local_file.aws_auth_configmap, var.eks_cluster_name]   

  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  subnet_id = var.public_subnet_id

  # You can use an existing key pair, or create a new one
  key_name = aws_key_pair.deployer.key_name

  iam_instance_profile = aws_iam_instance_profile.ec2_admin_instance_profile.name

  # Replace with your security group ID
  vpc_security_group_ids = [aws_security_group.bastion_host.id]

  # Recreate on user_data change
  user_data_replace_on_change = true

  # User data to run commands on instance start
  user_data = <<-EOF
      #!/bin/bash
      # Update and install necessary tools
      yum update
      yum install -y git docker jq
      
      # Add the default user to the Docker group
      usermod -aG docker ec2-user

      # Install AWS CLI
      curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
      unzip awscliv2.zip
      sudo ./aws/install

      # Fetch kubeconfig and apply to both root and ec2-user
      aws eks update-kubeconfig --region ${var.region} --name ${var.eks_cluster_name} --kubeconfig /home/ec2-user/.kube/config
      aws eks update-kubeconfig --region ${var.region} --name ${var.eks_cluster_name} --kubeconfig /root/.kube/config
      chown ec2-user:ec2-user /home/ec2-user/.kube/config

      # Install kubectl to interact with Kubernetes
      curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.30.2/2024-07-12/bin/linux/amd64/kubectl
      chmod +x ./kubectl
      mv ./kubectl /usr/local/bin/kubectl

      # Decode and save the Kubernetes YAML file
      echo '${local_file.aws_auth_configmap.content}' | base64 --decode > /tmp/configmap.yaml
      echo '${data.local_file.argo_cd_project.content_base64}' | base64 --decode > /tmp/argo_cd_project.yaml
      echo '${data.local_file.argo_cd_application.content_base64}' | base64 --decode > /tmp/argo_cd_application.yaml
      echo '${data.local_file.argo_cd_ignore_configmaps.content_base64}' | base64 --decode > /tmp/argo_cd_ignore_configmaps.yaml

      # Install Helm
      curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
      chmod 700 get_helm.sh
      ./get_helm.sh

      # Configure aliases
      echo 'alias k=kubectl' >> /home/ec2-user/.bashrc
      echo 'alias k=kubectl' >> /root/.bashrc

      # Install Argo CD
      su - ec2-user -c "kubectl create namespace argocd"
      su - ec2-user -c "kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"
      su - ec2-user -c "kubectl apply -f /tmp/argo_cd_ignore_configmaps.yaml"

      # Restart ArgoCD Deployments to load the new configmap
      su - ec2-user -c "kubectl rollout restart deployment argocd-server -n argocd"
      su - ec2-user -c "kubectl rollout restart deployment argocd-dex-server -n argocd"

      # Apply the Kubernetes configuration
      su - ec2-user -c "kubectl apply -f /tmp/configmap.yaml"
      su - ec2-user -c "kubectl apply -f /tmp/argo_cd_project.yaml"
      su - ec2-user -c "kubectl apply -f /tmp/argo_cd_application.yaml"

      # Install Argo CD CLI
      ARGOCD_VERSION=$(curl --silent "https://api.github.com/repos/argoproj/argo-cd/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
      curl -sSL -o /tmp/argocd-$ARGOCD_VERSION https://github.com/argoproj/argo-cd/releases/download/ARGOCD_VERSION/argocd-linux-amd64
      chmod +x /tmp/argocd-$ARGOCD_VERSION
      mv /tmp/argocd-$ARGOCD_VERSION /usr/local/bin/argocd

      # Install AWS Load Balancer Controller with correct kubeconfig
      helm repo add eks https://aws.github.io/eks-charts
      helm repo update
      helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
        -n kube-system \
        --set clusterName=${var.eks_cluster_name} \
        --set serviceAccount.create=false \
        --set serviceAccount.name=${var.alb_controller_service_account_name} \
        --set region=${var.region} \
        --set vpcId=${var.vpc_id} \
        --kubeconfig /root/.kube/config

      # Wait until argocd-server service is available
      until kubectl get svc argocd-server -n argocd --kubeconfig /root/.kube/config; do
          echo "Waiting for ArgoCD server to be available..."
          sleep 10
      done

      # Forward port 8080 to access Argo CD
      nohup kubectl port-forward svc/argocd-server -n argocd 8080:443 --kubeconfig /root/.kube/config > port-forward.log 2>&1 &
      
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

##################
## Github Actions Runner
##################

resource "aws_instance" "github_actions_runner" {
  depends_on = [local_file.aws_auth_configmap, var.eks_cluster_name]   

  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  subnet_id = var.public_subnet_id

  # You can use an existing key pair, or create a new one
  key_name = aws_key_pair.deployer.key_name

  iam_instance_profile = aws_iam_instance_profile.github_actions_runner_instance_profile.name

  # Replace with your security group ID
  vpc_security_group_ids = [aws_security_group.bastion_host.id]

  # Recreate on user_data change
  user_data_replace_on_change = true

  # User data to run commands on instance start
  user_data = <<-EOF
        #!/bin/bash
        # Update and install necessary tools
        apt-get update -y
        apt-get upgrade -y
        apt-get install -y git docker.io jq
        apt-get install -y unzip

        # Install dev tools
        apt-get install -y build-essential libssl-dev python3 python3-pip
        curl -sL https://deb.nodesource.com/setup_20.x | sudo -E bash -
        apt-get install -y nodejs
        
        # Add the default user to the Docker group
        usermod -aG docker ubuntu
        systemctl enable docker
        systemctl start docker

        # Install kubectl to interact with Kubernetes
        curl -o kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/1.18.9/2020-11-02/bin/linux/amd64/kubectl
        chmod +x ./kubectl
        mv ./kubectl /usr/local/bin/kubectl

        # Install AWS CLI
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        unzip awscliv2.zip
        sudo ./aws/install

        # Retrieve the GITHUB_TOKEN from AWS Secrets Manager
        GITHUB_TOKEN=$(aws secretsmanager get-secret-value --secret-id github_token_for_actions_runner --query SecretString --output text | jq -r '.github_token_for_actions_runner')

        RUNNER_TOKEN=$(curl -sX POST -H "Authorization: token $GITHUB_TOKEN" \
        https://api.github.com/repos/${var.github_account_org}/${var.github_account_repo}/actions/runners/registration-token | jq -r .token)

        # Run the GitHub Actions runner setup as the ubuntu user
        su - ubuntu -c "
          mkdir -p /home/ubuntu/actions-runner
          cd /home/ubuntu/actions-runner
          curl -o actions-runner-linux-x64-2.319.1.tar.gz -L https://github.com/actions/runner/releases/download/v2.319.1/actions-runner-linux-x64-2.319.1.tar.gz
          tar xzf ./actions-runner-linux-x64-2.319.1.tar.gz
          ./config.sh --url https://github.com/${var.github_account_org}/${var.github_account_repo} --token $RUNNER_TOKEN --unattended --name $(hostname) --labels self-hosted,ubuntu --work _work
          sudo ./svc.sh install
          sudo ./svc.sh start
        "

        # Switch from root to ubuntu user and fetching kubeconfig
        su - ubuntu -c "aws eks update-kubeconfig --region ${var.region} --name ${var.cluster_name}"

        echo 'export PATH=$PATH:/usr/local/bin' >> /home/ubuntu/.bashrc
        
      EOF

  # Optional: Set a tag to easily identify the instance
  tags = {
    Name = "GithubActionsRunnerInstance"
  }
}

resource "aws_iam_instance_profile" "github_actions_runner_instance_profile" {
  name = "github_actions_runner_instance_profile"
  role =  aws_iam_role.github_actions_runner_role.name
}

resource "aws_iam_role" "github_actions_runner_role" {
  name = "github_actions_runner_role"

  assume_role_policy = data.aws_iam_policy_document.bastion_host_trust_relationship_policy.json
}

resource "aws_iam_role_policy" "github_actions_runner_policy" {
  name = "github_actions_runner_policy"
  role = aws_iam_role.github_actions_runner_role.id

  policy = data.aws_iam_policy_document.github_runner_role_policy.json
}

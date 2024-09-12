**» Travel Guide IaC Repository «**

This repository creates all the necessary AWS infrastructure required for my Travel Guide project.

The infrastructure consists of 5 modules, each with distinct purposes:

**• Networking Module**

The core infrastructure module that creates a custom network in AWS with all of the necessary components that will be leveraged later during the EKS deployment.

**• Kubernetes Module**

This module deploys an EKS cluster with a private endpoint and public node groups (managed by AWS). It also creates an OIDC provider, allowing Kubernetes resources to communicate securely with the cloud provider.

**• Bastion Host Module**

As we are using an EKS private endpoint for enhanced security, this module deploys three EC2 machines serving various functions:

	•	Admin Host: This instance has full access to the Kubernetes API. Its user-data initialization script pre-configures the EKS cluster with IAM users’ configmaps and installs necessary resources on the cluster (e.g., ArgoCD, AWS Load Balancer Controller).
	•	Bastion Host: This host enables IAM users with the EKS admin role to interact with the Kubernetes API for troubleshooting infrastructure and cluster issues.
	•	GitHub Actions Runner: A self-hosted runner for the CI workflow, necessary due to the private EKS endpoint.

**• RDS Module**

This module deploys an RDS database on AWS, used by the web application. The secrets are created and rotated by AWS, and the application running on Kubernetes can securely fetch them via a properly configured OIDC pod role.

**• IAM Module**

Responsible for creating IAM users, most IAM policies, and a KMS key. This module contains the eks_admins.tf file, where a map(string) variable is provided to define the usernames of EKS admins. It creates IAM users and attaches the appropriate user policies. The same list of users is later used to enable SSM sessions to the bastion host.

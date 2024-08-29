output "update_kubeconfig_command" {
  value = "aws eks update-kubeconfig --region ${var.region} --name ${aws_eks_cluster.this.name} --kubeconfig ~/.kube/config_project"
  description = "Run this command to add the EKS cluster to your specified kubeconfig file."
}

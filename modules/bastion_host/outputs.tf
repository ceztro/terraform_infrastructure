output bastion_host_security_group_id {
  value = aws_security_group.bastion_host.id
}

output "instance_id" {
  value = aws_instance.eks_admin_host.id
}
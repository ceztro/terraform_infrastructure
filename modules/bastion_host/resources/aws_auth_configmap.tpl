apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: arn:aws:iam::${account_id}:role/bastion-host-role
      username: admin
      groups:
        - read-only
  mapUsers: |
%{ for user in usernames ~}
    - userarn: arn:aws:iam::${account_id}:user/${user}
      username: ${user}
      groups:
        - system:masters
%{ endfor ~}
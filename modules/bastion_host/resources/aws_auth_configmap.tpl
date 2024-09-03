apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: arn:aws:iam::${account_id}:role/github_actions_runner_role
      username: github-runner-user
      groups:
        - github-runner
    - rolearn: arn:aws:iam::${account_id}:role/travel-guide-eks-cluster-worker-role
      username: admin
      groups:
        - system:masters
  mapUsers: |
%{ for user in usernames ~}
    - userarn: arn:aws:iam::${account_id}:user/${user}
      username: ${user}
      groups:
        - system:masters
%{ endfor ~}
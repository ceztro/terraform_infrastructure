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
  mapUsers: |
%{ for user in usernames ~}
    - userarn: arn:aws:iam::${account_id}:user/${user}
      username: ${user}
      groups:
        - system:masters
%{ endfor ~}
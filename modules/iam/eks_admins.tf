variable "eks_admins" {
  type = map(string)
  default = {
    user1 = "eks-admin-Peter",
    user2 = "eks-admin-Denis"
  }
}
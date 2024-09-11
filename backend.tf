terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "Travel_Guide"

    workspaces {
      name = "terraform_infrastructure"
    }
  }
}
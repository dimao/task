provider "vsphere" {
  user           = var.vsphere_user
  password       = var.vsphere_password
  vsphere_server = var.vsphere_server

  allow_unverified_ssl = true
}

terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "intes"

    workspaces {
      name = "adintilligence"
    }
  }
}
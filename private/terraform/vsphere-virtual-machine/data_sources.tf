data "vsphere_datacenter" "dc" {
  name = var.datacenter
}

data "vsphere_resource_pool" "pool" {
  count         = var.resource_pool != "" ? 1 : 0
  name          = var.resource_pool
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_datastore" "ds" {
  name          = var.datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network" {
  name          = var.network
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "template" {
  count         = var.template_name != "" ? 1 : 0
  name          = var.template_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_tag_category" "category" {
  count = var.tag_category != "" ? 1 : 0
  name  = var.tag_category
}

data "vsphere_tag" "tag" {
  count       = var.tag_name != "" ? 1 : 0
  name        = var.tag_name
  category_id = data.vsphere_tag_category.category[0].id
}

# vim: filetype=terraform

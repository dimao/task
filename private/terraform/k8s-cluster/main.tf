module "k8s-masters" {
  source             = "git::https://gitlab.intes.by/terraform/vsphere-virtual-machine.git"
  datacenter         = "its-dc"
  datastore          = "vmstorage"
  template_name      = "centos-golden"
  template_os_family = "linux"
  network            = "VM Network"
  resource_pool      = "cl1/Resources"
  # VM settings
  vm_count       = "3"
  vm_name_prefix = "k8s-master"
  num_cpus       = "2"
  memory         = "2048"
}

module "k8s-nodes" {
  source             = "git::https://gitlab.intes.by/terraform/vsphere-virtual-machine.git"
  datacenter         = "its-dc"
  datastore          = "vmstorage"
  template_name      = "centos-golden"
  template_os_family = "linux"
  network            = "VM Network"
  resource_pool      = "cl1/Resources"
  # VM settings
  vm_count       = "2"
  vm_name_prefix = "k8s-node"
  num_cpus       = "2"
  memory         = "2048"
}

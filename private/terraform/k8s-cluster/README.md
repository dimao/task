# terraform-vsphere-intes-prod

Configuration for vsphere production deployment with automatic SaltStack provision and Veeam vm backups

## Usage Example:

```bash
terraform apply -var='vsphere_user=administrator@vsphere.local' -var='vsphere_server=vcsa.its.local' -var='vsphere_password=' -var='veeam_password='
```

#### main.tf:
```
module "prometheus" {
  source             = "git::https://gitlab.intes.by/terraform/vsphere-virtual-machine.git"
  datacenter         = "its-dc"
  datastore          = "vmstorage"
  template_name      = "centos-golden"
  template_os_family = "linux"
  network            = "VM Network"
  resource_pool      = "cl1/Resources"
  # VM settings
  vm_count             = "1"
  vm_name_prefix       = "prometheus"
  num_cpus             = "4"
  memory               = "4096"
  ipv4_network_address = "192.168.1.0/24"
  ipv4_address_start   = "12"
  ipv4_gateway         = "192.168.1.1"
  dns_servers          = ["192.168.1.3", "8.8.8.8"]
  domain_name          = "its.local"
  # Provision settings
  provision             = "true"
  private_key_path      = "~/.ssh/id_rsa"
  provision_script_path = "scripts/provision.sh"
  tag_name              = "consul"
  # Veeam settings
  backup            = "true"
  veeam_job_name    = "regular"
  veeam_host        = var.veeam_host
  veeam_user        = var.veeam_user
  veeam_password    = var.veeam_password
  veeam_script_path = var.veeam_script_path
  veeam_script_dest = var.veeam_script_dest
}
```
#### provision.sh:

Define SALT_VERSION and BOOTSTRAP_SALT_CHECKSUM from salt-bootstrap [GitHub]



[GitHub]: https://github.com/saltstack/salt-bootstrap
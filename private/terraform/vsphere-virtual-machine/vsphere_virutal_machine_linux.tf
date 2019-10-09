resource "vsphere_virtual_machine" "virtual_machine_linux" {
  count            = var.template_os_family == "linux" ? var.vm_count : 0
  name             = "${var.vm_name_prefix}-${count.index}"
  resource_pool_id = data.vsphere_resource_pool.pool[0].id
  datastore_id     = data.vsphere_datastore.ds.id
  nested_hv_enabled          = var.nested_hv_enabled
  tags = [data.vsphere_tag.tag[0].id]
  num_cpus = var.num_cpus
  memory   = var.memory
  guest_id = data.vsphere_virtual_machine.template[0].guest_id
  wait_for_guest_net_timeout = var.wait_for_guest_net_timeout

  network_interface {
    network_id = data.vsphere_network.network.id
  }

  disk {
    label            = "disk0"
    size             = var.disk_size != "" ? var.disk_size : data.vsphere_virtual_machine.template[0].disks[0].size
    thin_provisioned = data.vsphere_virtual_machine.template[0].disks[0].thin_provisioned
    eagerly_scrub    = data.vsphere_virtual_machine.template[0].disks[0].eagerly_scrub
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template[0].id

    customize {
      linux_options {
        host_name = "${var.vm_name_prefix}-${count.index}"
        domain    = var.domain_name
        time_zone = var.time_zone != "" ? var.time_zone : "UTC"
      }

      network_interface {
        ipv4_address = var.ipv4_network_address != "0.0.0.0/0" ? cidrhost(
          var.ipv4_network_address,
          var.ipv4_address_start + count.index,
        ) : ""
        ipv4_netmask = var.ipv4_network_address != "0.0.0.0/0" ? element(split("/", var.ipv4_network_address), 1) : 0
      }

      ipv4_gateway    = var.ipv4_gateway
      dns_server_list = var.dns_servers
      dns_suffix_list = [var.domain_name]
    }
  }
}

resource "null_resource" "virtual-machine-provision" {
  //count = "${length(module.virtual-machine.virtual_machine_names)}"

  count = var.provision == "true" && var.template_os_family == "linux" ? var.vm_count : 0
  triggers = {
    virtual_machine_ids = vsphere_virtual_machine.virtual_machine_linux[count.index].id
  }

  connection {
    host        = vsphere_virtual_machine.virtual_machine_linux[count.index].default_ip_address
    type        = "ssh"
    user        = "root"
    private_key = file(var.private_key_path)
  }

  provisioner "remote-exec" {
    script = var.provision_script_path
  }
}

resource "null_resource" "delete-salt-key" {

  count = var.provision == "true" && var.template_os_family == "linux" ? var.vm_count : 0

  connection {
    host        = var.salt_host
    type        = "ssh"
    user        = "root"
    private_key = file(var.private_key_path)
  }

  provisioner "remote-exec" {
    when = destroy
    inline = [
      "salt-key -d ${var.vm_name_prefix}-${count.index}* -y",
    ]
  }
}

resource "null_resource" "virtual-machine-veeam-backup" {

  count = var.backup == "true" && var.template_os_family == "linux" ? var.vm_count : 0

  triggers = {
    virtual_machine_ids = vsphere_virtual_machine.virtual_machine_linux[count.index].id
  }

  provisioner "file" {

    source      = var.veeam_script_path
    destination = var.veeam_script_dest

    connection {
      host     = var.veeam_host
      type     = "winrm"
      user     = var.veeam_user
      password = var.veeam_password
      insecure = "true"
    }
  }

  provisioner "remote-exec" {

    connection {
      host     = var.veeam_host
      type     = "winrm"
      user     = var.veeam_user
      password = var.veeam_password
      insecure = "true"
    }

    inline = [
      "powershell -ExecutionPolicy Unrestricted -File ${var.veeam_script_dest} -vm_name ${var.vm_name_prefix}-${count.index} -job_name ${var.veeam_job_name} -veeam_host ${var.veeam_host} -veeam_user ${var.veeam_user} -veeam_password ${var.veeam_password}",
    ]
  }
}


resource "null_resource" "virtual-machine-veeam-backup-remove-vm" {

  count = var.backup == "true" && var.template_os_family == "linux" ? var.vm_count : 0

  triggers = {
    virtual_machine_ids = vsphere_virtual_machine.virtual_machine_linux[count.index].id
  }

  provisioner "remote-exec" {

    when = destroy

    connection {
      host     = var.veeam_host
      type     = "winrm"
      user     = var.veeam_user
      password = var.veeam_password
      insecure = "true"
    }

    inline = [
      "powershell -ExecutionPolicy Unrestricted -File ${var.veeam_script_dest} -vm_name ${var.vm_name_prefix}-${count.index} -job_name ${var.veeam_job_name} -veeam_host ${var.veeam_host} -veeam_user ${var.veeam_user} -veeam_password ${var.veeam_password} -remove_vm true ",
    ]
  }
}

# vim: filetype=terraform

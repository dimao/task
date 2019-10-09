resource "vsphere_virtual_machine" "virtual_machine_windows" {
  count                      = var.template_os_family == "windows" ? var.vm_count : 0
  name                       = "${var.vm_name_prefix}-${count.index}"
  resource_pool_id           = data.vsphere_resource_pool.pool[0].id
  datastore_id               = data.vsphere_datastore.ds.id
  num_cpus                   = var.num_cpus
  memory                     = var.memory
  guest_id                   = data.vsphere_virtual_machine.template[0].guest_id
  scsi_type                  = data.vsphere_virtual_machine.template[0].scsi_type
  wait_for_guest_net_timeout = var.wait_for_guest_net_timeout
  tags                       = [data.vsphere_tag.tag[0].id]
  nested_hv_enabled          = var.nested_hv_enabled

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
      windows_options {
        computer_name         = "${var.vm_name_prefix}-${count.index}"
        workgroup             = var.workgroup
        admin_password        = var.admin_password
        join_domain           = var.join_domain
        domain_admin_user     = var.domain_admin_user
        domain_admin_password = var.domain_admin_password
        time_zone             = var.time_zone != "" ? var.time_zone : "130"
        auto_logon            = true
        run_once_command_list = [
          "winrm quickconfig -q",
          "winrm set winrm/config/service @{AllowUnencrypted=\"true\"}",
          "winrm set winrm/config/service/auth @{Basic=\"true\"}",
          "Start-Service WinRM",
          "set-service WinRM -StartupType Automatic",
          "netsh advfirewall set allprofiles state off",
        ]
      }
      network_interface {
        ipv4_address = var.ipv4_network_address != "0.0.0.0/0" ? cidrhost(
          var.ipv4_network_address,
          var.ipv4_address_start + count.index,
        ) : ""
        ipv4_netmask    = var.ipv4_network_address != "0.0.0.0/0" ? element(split("/", var.ipv4_network_address), 1) : 0
        dns_server_list = var.dns_servers
        dns_domain      = var.domain_name
      }

      ipv4_gateway = var.ipv4_gateway
    }
  }
}

resource "null_resource" "virtual-machine-provision-windows" {

  count = var.provision == "true" && var.template_os_family == "windows" ? var.vm_count : 0
  triggers = {
    virtual_machine_ids = vsphere_virtual_machine.virtual_machine_windows[count.index].id
  }

  provisioner "file" {

    source      = var.provision_script_path
    destination = var.provision_script_dest

    connection {
      host     = vsphere_virtual_machine.virtual_machine_windows[count.index].default_ip_address
      type     = "winrm"
      user     = "Administrator"
      password = var.admin_password
      insecure = "true"
    }
  }

  provisioner "remote-exec" {

    connection {
      host     = vsphere_virtual_machine.virtual_machine_windows[count.index].default_ip_address
      type     = "winrm"
      user     = "Administrator"
      password = var.admin_password
      insecure = "true"
    }

    inline = [
      "powershell -ExecutionPolicy Unrestricted -File ${var.provision_script_dest} -bootstrapVersion ${var.salt_bootstrap_version} -saltVersion ${var.salt_version}",
    ]
  }
}

resource "null_resource" "delete-salt-key-windows" {

  count = var.provision == "true" && var.template_os_family == "windows" ? var.vm_count : 0

  connection {
    host        = var.salt_host
    type        = "ssh"
    user        = "root"
    private_key = file(var.private_key_path)
  }

  provisioner "remote-exec" {
    when = destroy
    inline = [
      "salt-key -d ${var.vm_name_prefix}-${count.index}.* -y",
    ]
  }
}

resource "null_resource" "consul_leave" {

  count = var.provision == "true" && var.template_os_family == "windows" ? var.vm_count : 0

  connection {
    host     = vsphere_virtual_machine.virtual_machine_windows[count.index].default_ip_address
    type     = "winrm"
    user     = "Administrator"
    password = var.admin_password
    insecure = "true"
  }

  provisioner "remote-exec" {
    when = destroy
    inline = [
      "curl --request PUT http://127.0.0.1:8500/v1/agent/leave"
    ]

  }
}

data "template_file" "winrm_script" {

  count    = var.template_os_family == "windows" ? var.vm_count : 0
  template = "${file(var.winrm_script_path)}"
  vars = {
    default_ip_address = vsphere_virtual_machine.virtual_machine_windows[count.index].default_ip_address
  }
}

resource "null_resource" "virtual-machine-prepare-winrm" {

  count = var.template_os_family == "windows" ? var.vm_count : 0
  triggers = {
    virtual_machine_ids = vsphere_virtual_machine.virtual_machine_windows[count.index].id
  }



  provisioner "file" {

    content      = data.template_file.winrm_script[count.index].rendered
    destination = var.winrm_script_dest

    connection {
      host     = vsphere_virtual_machine.virtual_machine_windows[count.index].default_ip_address
      type     = "winrm"
      user     = "Administrator"
      password = var.admin_password
      insecure = "true"
    }
  }

  provisioner "remote-exec" {

    connection {
      host     = vsphere_virtual_machine.virtual_machine_windows[count.index].default_ip_address
      type     = "winrm"
      user     = "Administrator"
      password = var.admin_password
      insecure = "true"
    }

    inline = [
      "powershell -ExecutionPolicy Unrestricted -File ${var.winrm_script_dest}",
    ]
  }
}

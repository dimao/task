variable "vsphere_user" {
  default = ""
}

variable "vsphere_password" {
  default = ""
}

variable "vsphere_server" {
  default = ""
}

variable "veeam_host" {
  default = "veeam"
}

variable "veeam_user" {
  default = "Administrator"
}

variable "veeam_password" {
  default = ""
}

variable "veeam_script_path" {
  default = "scripts/add_vbr_job_object.ps1"
}

variable "veeam_script_dest" {
  default = "C:\\add_vbr_job_object.ps1"
}

variable "provision_script_dest" {
  default = ""
}

variable "salt_bootstrap_version" {
  default = ""
}

variable "salt_version" {
  default = ""
}

variable "join_domain" {
  default = ""
}

variable "domain_admin_user" {
  default = ""
}

variable "domain_admin_password" {
  default = ""
}

variable "admin_password" {
  default = ""
}

variable "winrm_script_path" {
  default = "scripts/ConfigureRemotingForAnsible.ps1"
}

variable "winrm_script_dest" {
  default = "C:\\ConfigureRemotingForAnsible.ps1"
}
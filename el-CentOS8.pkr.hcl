variable "headless" {
  type    = string
  default = "true"
}

variable "shutdown_command" {
  type    = string
  default = "sudo /sbin/halt -p"
}

variable "version" {
  type    = string
  default = "2105"
}

variable "disk_size" {
  type    = string
  default = "320000"
}

variable "vm_name" {
  type    = string
  default = "packer-centos-8-server"
}

variable "url" {
  type    = string
  default = "http://mirror.pulsant.com/sites/centos/8.5.2111/isos/x86_64/CentOS-8.5.2111-x86_64-dvd1.iso"
}

variable "checksum" {
  type    = string
  default = "3b795863001461d4f670b0dedd02d25296b6d64683faceb8f2b60c53ac5ebb3e"
}

source "virtualbox-iso" "virtualbox" {
  boot_command           = ["<tab> text inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ks.cfg<enter><wait>"]
  disk_size              = "100000"
  guest_additions_path   = "VBoxGuestAdditions_{{ .Version }}.iso"
  guest_additions_sha256 = "b81d283d9ef88a44e7ac8983422bead0823c825cbfe80417423bd12de91b8046"
  guest_os_type          = "RedHat_64"
  hard_drive_interface   = "sata"
  headless               = "${var.headless}"
  http_directory         = "http"
  iso_checksum           = "sha256:${var.checksum}"
  iso_url                = "${var.url}"
  shutdown_command       = "${var.shutdown_command}"
  ssh_password           = "vagrant"
  ssh_timeout            = "20m"
  ssh_username           = "vagrant"
  vboxmanage             = [[ "modifyvm", "{{ .Name }}", "--memory", "2024"], [ "modifyvm", "{{ .Name }}", "--cpus", "2" ]]
}

source "vmware-iso" "vmware" {
  boot_command                   = ["<tab> text inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ks.cfg<enter><wait>"]
  disk_size                      = "${var.disk_size}"
  guest_os_type                  = "centos-64"
  headless                       = "${var.headless}"
  http_directory                 = "http"
  iso_checksum                   = "sha256:${var.checksum}"
  iso_url                        = "${var.url}"
  shutdown_command               = "${var.shutdown_command}"
  ssh_password                   = "vagrant"
  ssh_timeout                    = "20m"
  ssh_username                   = "vagrant"
  tools_upload_flavor            = "linux"
  vmx_remove_ethernet_interfaces = "true"
  output_directory               = "output-${var.vm_name}-vmware-iso"
  vm_name                        = "${var.vm_name}"
}

build {
  sources = ["source.virtualbox-iso.virtualbox", "source.vmware-iso.vmware"]

  provisioner "shell" {
    execute_command = "sudo {{ .Vars }} sh {{ .Path }}"
    scripts         = ["scripts/vagrant.sh", "scripts/update.sh", "scripts/vmtools.sh", "scripts/zerodisk.sh"]
  }

  post-processor "vagrant" {
    output = "CentOS-8-x86_64-${var.version}-${source.name}.box"
  }
  
  post-processor "shell-local" {
    inline = [
        "rm -rf ${var.vm_name}.ova || true",
        "ovftool output-${var.vm_name}-vmware-iso/${var.vm_name}.vmx ${var.vm_name}.ova"
      ]
  }
}

provider "vsphere" {
  user                 = "${var.vsphere["USER"]}"
  password             = "${var.vsphere["PASSWORD"]}"
  vsphere_server       = "${var.vsphere["SERVER"]}"
  allow_unverified_ssl = "${var.vsphere["UNVERIFIED_SSL"]}"
}

resource "vsphere_virtual_machine" "vm" {
  count      = "${length(var.IPV4_ADDRESS)}"
  name       = "${var.name}-${count.index}"
  folder     = "${var.vm["FOLDER"]}"
  datacenter = "${var.vm["DATACENTER"]}"
  vcpu       = "${var.vm["VCPU"]}"
  memory     = "${var.vm["MEMORY"]}"
  memory_reservation = 1024

  network_interface {
    label              = "VM Network"
    ipv4_address       = "${element(var.IPV4_ADDRESS, count.index)}"
    ipv4_prefix_length = "24"
    ipv4_gateway       = "${var.vm["DEFAULT_GATEWAY"]}"
  }

  disk {
    datastore = "${var.vm["DATASTORE"]}"
    template  = "${var.vm["TEMPLATE"]}"
    type      = "thin"
  }
}

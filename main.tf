module "cluster" {

  source = "modules/cluster"

  vsphere                 = "${var.vsphere}"
  domain_cluster          = "${var.domain_cluster}"
  path_certs              = "${var.path_certs}"

  vm_manager              = "${var.vm_manager}"
  vm_worker               = "${var.vm_worker}"

  name_manager            = "${var.name_manager}"
  name_worker             = "${var.name_worker}"

  IPV4_ADDRESS_manager    = "${var.IPV4_ADDRESS_manager}"
  IPV4_ADDRESS_worker     = "${var.IPV4_ADDRESS_worker}"

}

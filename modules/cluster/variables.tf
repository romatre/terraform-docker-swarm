variable "vsphere" {
  type = "map"
}

variable "vm_manager" {
  type = "map"

  default = {
    VCPU     = 2
    MEMORY   = 4096
    SSH_USER = "root"
  }
}

variable "vm_worker" {
  type = "map"

  default = {
    VCPU     = 2
    MEMORY   = 4096
    SSH_USER = "root"
  }
}

variable "domain_cluster" {
  type = "string"
}

variable "name_manager" {
  type    = "string"
  default = "manager"
}

variable "name_worker" {
  type    = "string"
  default = "manager"
}

variable "path_certs" {
  type = "string"
}

variable "IPV4_ADDRESS_manager" {
  type = "list"
}

variable "IPV4_ADDRESS_worker" {
  type = "list"
}
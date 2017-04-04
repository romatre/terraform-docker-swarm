variable "vsphere" {
  type = "map"

  default = {
    UNVERIFIED_SSL = true
  }
}

variable "name" {
  type    = "string"
  default = "vm"
}

variable "vm" {
  type = "map"

  default = {
    VCPU     = 2
    MEMORY   = 4096
    SSH_USER = "root"
  }
}

variable "IPV4_ADDRESS" {
  type = "list"
}

variable "MAC_ADDRESS" {
  type = "list"
}

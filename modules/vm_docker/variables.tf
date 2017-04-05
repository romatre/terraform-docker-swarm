variable "vsphere" {
  type = "map"
}

variable "vm" {
  type = "map"

  default = {
    VCPU     = 2
    MEMORY   = 4096
    SSH_USER = "root"
  }
}

variable "path_certs" {
  type = "string"
}

variable "name" {
  type    = "string"
  default = "docker"
}

variable "IPV4_ADDRESS" {
  type = "list"
}

variable "MAC_ADDRESS" {
  type = "list"
}

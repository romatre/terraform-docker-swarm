variable "vsphere" {
  type = "map"
  default = {
    UNVERIFIED_SSL = true
  }
}

variable "manager_hardware" {
  type = "map"
  default = {
    VCPU = 2
    MEMORY = 4096
  }
}

variable "manager_number" {
  default = 3
}

variable "manager_ipv4" {
  type = "map"
}

variable "worker_hardware" {
  type = "map"
  default = {
    VCPU = 2
    MEMORY = 4096
  }
}


variable "worker_number" {
  default = 3
}

variable "worker_ipv4" {
  type = "map"
}

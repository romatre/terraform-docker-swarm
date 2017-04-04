# managers created
module "manager" {
  source = "../vm_docker"

  vsphere    = "${var.vsphere}"
  path_certs = "${var.path_certs}"

  name         = "${var.name_manager}"
  vm           = "${var.vm_manager}"
  IPV4_ADDRESS = "${var.IPV4_ADDRESS_manager}"
  MAC_ADDRESS  = "${var.MAC_ADDRESS_manager}"
}

# workers created
module "worker" {
  source = "../vm_docker"

  vsphere    = "${var.vsphere}"
  path_certs = "${var.path_certs}"

  name         = "${var.name_worker}"
  vm           = "${var.vm_worker}"
  IPV4_ADDRESS = "${var.IPV4_ADDRESS_worker}"
  MAC_ADDRESS  = "${var.MAC_ADDRESS_worker}"
}

# swarm init on master manager
resource "null_resource" "init" {
  depends_on = ["module.manager"]

  connection {
    user        = "${var.vsphere["SSH_USER"]}"
    private_key = "${file("${var.vsphere["SSH_KEY"]}")}"
    host        = "${element(var.IPV4_ADDRESS_manager, 0)}"
  }

  provisioner "remote-exec" {
    inline = [
      "docker swarm init --advertise-addr ${element(var.IPV4_ADDRESS_manager, 0)}",
    ]
  }
}

# add cluster host to managers
resource "null_resource" "add_cluster_host_manager" {
  depends_on = ["module.manager"]

  count = "${length(var.IPV4_ADDRESS_manager)}"

  connection {
    user        = "${var.vsphere["SSH_USER"]}"
    private_key = "${file("${var.vsphere["SSH_KEY"]}")}"
    host        = "${element(var.IPV4_ADDRESS_manager, count.index)}"
  }

  provisioner "remote-exec" {
    inline = [
      "echo \"${element(var.IPV4_ADDRESS_manager, count.index)}  ${var.host_cluster}\" >> /etc/hosts",
    ]
  }
}

# add cluster host to workers
resource "null_resource" "add_cluster_host_worker" {
  depends_on = ["module.manager"]

  count = "${length(var.IPV4_ADDRESS_worker)}"

  connection {
    user        = "${var.vsphere["SSH_USER"]}"
    private_key = "${file("${var.vsphere["SSH_KEY"]}")}"
    host        = "${element(var.IPV4_ADDRESS_worker, count.index)}"
  }

  provisioner "remote-exec" {
    inline = [
      "echo \"${element(var.IPV4_ADDRESS_worker, count.index)}  ${var.host_cluster}\" >> /etc/hosts",
    ]
  }
}

# the managers join the cluster
resource "null_resource" "join_manager" {
  depends_on = ["null_resource.init", "null_resource.add_cluster_host_manager"]

  count = "${length(var.IPV4_ADDRESS_manager) - 1}"

  connection {
    user        = "${var.vsphere["SSH_USER"]}"
    private_key = "${file("${var.vsphere["SSH_KEY"]}")}"
    host        = "${element(var.IPV4_ADDRESS_manager, count.index + 1)}"
  }

  provisioner "remote-exec" {
    inline = [
      "docker swarm join --token $(docker -H tcp://${var.host_cluster}:2377 --tlsverify swarm join-token -q manager)",
    ]
  }
}

# the workers join the cluster
resource "null_resource" "join_worker" {
  depends_on = ["module.worker", "null_resource.add_cluster_host_worker"]

  connection {
    user        = "${var.vsphere["SSH_USER"]}"
    private_key = "${file("${var.vsphere["SSH_KEY"]}")}"
    host        = "${element(var.IPV4_ADDRESS_worker, 0)}"
  }

  provisioner "remote-exec" {
    inline = [
      "docker swarm join --token $(docker -H tcp://${var.host_cluster}:2377 --tlsverify swarm join-token -q worker)",
    ]
  }
}

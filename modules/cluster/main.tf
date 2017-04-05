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

# the managers join the cluster
resource "null_resource" "join_manager" {
  depends_on = ["module.manager", "null_resource.init"]

  count = "${length(var.IPV4_ADDRESS_manager) - 1}"

  connection {
    user        = "${var.vsphere["SSH_USER"]}"
    private_key = "${file("${var.vsphere["SSH_KEY"]}")}"
    host        = "${element(var.IPV4_ADDRESS_manager, count.index + 1)}"
  }

  provisioner "remote-exec" {
    inline = [
      "export DOCKER_CERT_PATH=/root/.docker",
      "docker swarm join --token $(docker -H tcp://${var.host_cluster}:2376 --tlsverify swarm join-token -q manager) ${var.host_cluster}:2377",
    ]
  }
}

# the workers join the cluster
resource "null_resource" "join_worker" {
  depends_on = ["module.worker", "null_resource.init"]

  connection {
    user        = "${var.vsphere["SSH_USER"]}"
    private_key = "${file("${var.vsphere["SSH_KEY"]}")}"
    host        = "${element(var.IPV4_ADDRESS_worker, count.index)}"
  }

  provisioner "remote-exec" {
    inline = [
      "export DOCKER_CERT_PATH=/root/.docker",
      "docker swarm join --token $(docker -H tcp://${var.host_cluster}:2376 --tlsverify swarm join-token -q worker) ${var.host_cluster}:2377",
    ]
  }
}

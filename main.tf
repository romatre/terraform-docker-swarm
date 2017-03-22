provider "vsphere" {
  user = "${var.vsphere["USER"]}"
  password = "${var.vsphere["PASSWORD"]}"
  vsphere_server = "${var.vsphere.["SERVER"]}"
  allow_unverified_ssl = "${var.vsphere.["UNVERIFIED_SSL"]}"
}

resource "null_resource" "generate-certs-manager" {
  count = "${var.manager_number}"
  provisioner "local-exec" {
    command = "docker run --rm -e SSL_IP=${lookup(var.manager_ipv4, count.index)} -e SSL_DNS=swarm-manager-${count.index} -v $(pwd)/resources/certs/swarm-manager-${count.index}:/certs paulczar/omgwtfssl"
  }
}

resource "null_resource" "generate-certs-worker" {
  count = "${var.worker_number}"
  provisioner "local-exec" {
    command = "docker run --rm -e SSL_IP=${lookup(var.worker_ipv4, count.index)} -e SSL_DNS=swarm-worker-${count.index} -v $(pwd)/resources/certs/swarm-worker-${count.index}:/certs paulczar/omgwtfssl"
  }
}

resource "vsphere_virtual_machine" "swarm-manager" {

  depends_on = ["null_resource.generate-certs-manager"]
  count = "${var.manager_number}"

  name = "swarm-manager-${count.index}"
  folder = "${var.vsphere.["FOLDER"]}"
  datacenter = "${var.vsphere.["DATACENTER"]}"
  vcpu = "${var.manager_hardware.["VCPU"]}"
  memory = "${var.manager_hardware.["MEMORY"]}"

  connection {
    user = "${var.vsphere.["SSH_USER"]}"
    private_key = "${file("${var.vsphere.["SSH_KEY"]}")}"
    host = "${lookup(var.manager_ipv4, count.index)}"
  }

  network_interface {
    label = "VM Network"
    ipv4_address = "${lookup(var.manager_ipv4, count.index)}"
    ipv4_prefix_length = "24"
    ipv4_gateway = "${var.vsphere.["DEFAULT_GATEWAY"]}"
  }

  disk {
    datastore = "${var.manager_hardware.["DATASTORE"]}"
    template = "${var.manager_hardware.["TEMPLATE"]}"
    type = "thin"
  }

  provisioner "file" {
    source      = "resources/scripts/bootstrap.sh"
    destination = "/tmp/bootstrap.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/bootstrap.sh",
      "/tmp/bootstrap.sh"
    ]
  }

  provisioner "file" {
    source      = "resources/docker.service.d"
    destination = "/etc/systemd/system"
  }

  provisioner "file" {
    source      = "resources/certs/swarm-manager-${count.index}/"
    destination = "/etc/docker/certs"
  }

  provisioner "remote-exec" {
    inline = [
      "systemctl daemon-reload",
      "systemctl enable docker",
      "systemctl restart docker",
    ]
  }

}

resource "vsphere_virtual_machine" "swarm-worker" {
  depends_on = ["null_resource.generate-certs-manager", "null_resource.generate-certs-worker"]
  count = "${var.worker_number}"

  name = "swarm-worker-${count.index}"
  folder = "${var.vsphere.["FOLDER"]}"
  datacenter = "${var.vsphere.["DATACENTER"]}"
  vcpu = "${var.worker_hardware.["VCPU"]}"
  memory = "${var.worker_hardware.["MEMORY"]}"

  connection {
    user = "${var.vsphere.["SSH_USER"]}"
    private_key = "${file("${var.vsphere.["SSH_KEY"]}")}"
    host = "${lookup(var.worker_ipv4, count.index)}"
  }

  network_interface {
    label = "VM Network"
    ipv4_address = "${lookup(var.worker_ipv4, count.index)}"
    ipv4_prefix_length = "24"
    ipv4_gateway = "${var.vsphere.["DEFAULT_GATEWAY"]}"
  }

  disk {
    datastore = "${var.worker_hardware.["DATASTORE"]}"
    template = "${var.worker_hardware.["TEMPLATE"]}"
    type = "thin"
  }

  provisioner "file" {
    source      = "resources/scripts/bootstrap.sh"
    destination = "/tmp/bootstrap.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/bootstrap.sh",
      "/tmp/bootstrap.sh"
    ]
  }

  provisioner "file" {
    source      = "resources/docker.service.d"
    destination = "/etc/systemd/system"
  }

  provisioner "file" {
    source      = "resources/certs/swarm-worker-${count.index}/"
    destination = "/etc/docker/certs"
  }

  provisioner "remote-exec" {
    inline = [
      "systemctl daemon-reload",
      "systemctl enable docker",
      "systemctl restart docker",
    ]
  }

}

resource "null_resource" "save-secret" {

  depends_on = ["vsphere_virtual_machine.swarm-manager", "vsphere_virtual_machine.swarm-worker"]

  provisioner "local-exec" {
    command = "docker -H tcp://${lookup(var.manager_ipv4, 0)}:2376 --tlsverify --tlscacert=$(pwd)/resources/certs/swarm-manager-0/ca.pem --tlscert=$(pwd)/resources/certs/swarm-manager-0/cert.pem --tlskey=$(pwd)/resources/certs/swarm-manager-0/key.pem swarm init"
  }

  provisioner "local-exec" {
    command = "docker -H tcp://${lookup(var.manager_ipv4, 0)}:2376 --tlsverify --tlscacert=$(pwd)/resources/certs/swarm-manager-0/ca.pem --tlscert=$(pwd)/resources/certs/swarm-manager-0/cert.pem --tlskey=$(pwd)/resources/certs/swarm-manager-0/key.pem swarm join-token -q manager > $(pwd)/resources/scripts/join-manager.sh"
  }

  provisioner "local-exec" {
    command = "docker -H tcp://${lookup(var.manager_ipv4, 0)}:2376 --tlsverify --tlscacert=$(pwd)/resources/certs/swarm-manager-0/ca.pem --tlscert=$(pwd)/resources/certs/swarm-manager-0/cert.pem --tlskey=$(pwd)/resources/certs/swarm-manager-0/key.pem swarm join-token -q worker > $(pwd)/resources/scripts/join-worker.sh"
  }

  provisioner "local-exec" {
    command = "echo \"docker swarm join --token $(cat $(pwd)/resources/scripts/join-manager.sh) ${lookup(var.manager_ipv4, 0)}:2377\" > $(pwd)/resources/scripts/join-manager.sh"
  }

  provisioner "local-exec" {
    command = "echo \"docker swarm join --token $(cat $(pwd)/resources/scripts/join-worker.sh) ${lookup(var.manager_ipv4, 0)}:2377\" > $(pwd)/resources/scripts/join-worker.sh"
  }

}

resource "null_resource" "join-manager" {
  depends_on = ["null_resource.save-secret"]

  count = "${var.manager_number - 1}"

  connection {
    user = "${var.vsphere.["SSH_USER"]}"
    private_key = "${file("${var.vsphere.["SSH_KEY"]}")}"
    host = "${lookup(var.manager_ipv4, count.index + 1)}"
  }

  provisioner "file" {
    source      = "resources/scripts/join-manager.sh"
    destination = "/tmp/join-manager.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/join-manager.sh",
      "/tmp/join-manager.sh"
    ]
  }
}

resource "null_resource" "join-worker" {
  depends_on = ["null_resource.save-secret"]

  count = "${var.worker_number}"

  connection {
    user = "${var.vsphere.["SSH_USER"]}"
    private_key = "${file("${var.vsphere.["SSH_KEY"]}")}"
    host = "${lookup(var.worker_ipv4, count.index)}"
  }

  provisioner "file" {
    source      = "resources/scripts/join-worker.sh"
    destination = "/tmp/join-worker.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/join-worker.sh",
      "/tmp/join-worker.sh"
    ]
  }
}

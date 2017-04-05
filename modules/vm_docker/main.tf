module "vm_docker" {
  source = "../vm"

  name         = "${var.name}"
  vsphere      = "${var.vsphere}"
  vm           = "${var.vm}"
  IPV4_ADDRESS = "${var.IPV4_ADDRESS}"
  MAC_ADDRESS  = "${var.MAC_ADDRESS}"
}

resource "null_resource" "boot-vm_docker" {
  depends_on = ["module.vm_docker"]

  count = "${length(var.IPV4_ADDRESS)}"

  connection {
    user        = "${var.vsphere["SSH_USER"]}"
    private_key = "${file("${var.vsphere["SSH_KEY"]}")}"
    host        = "${element(var.IPV4_ADDRESS, count.index)}"
  }

  provisioner "file" {
    source      = "${path.module}/files/docker.service.d"
    destination = "/etc/systemd/system"
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /root/.docker",
    ]
  }

  provisioner "file" {
    source      = "${var.path_certs}/"
    destination = "/root/.docker"
  }

  provisioner "remote-exec" {
    script = "${path.module}/files/bootstrap.sh"
  }

}

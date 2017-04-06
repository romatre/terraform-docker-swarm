module "vm_docker" {
  source = "../vm"

  name         = "${var.name}"
  vsphere      = "${var.vsphere}"
  vm           = "${var.vm}"
  IPV4_ADDRESS = "${var.IPV4_ADDRESS}"
}

data "template_file" "override_conf" {
  template = "${file("${path.module}/files/docker.service.d/override.conf")}"

  vars {
    domain_cluster = "${var.domain_cluster}"
  }
}

resource "null_resource" "boot-vm_docker" {
  depends_on = ["module.vm_docker"]

  count = "${length(var.IPV4_ADDRESS)}"

  connection {
    user        = "${var.vm["SSH_USER"]}"
    private_key = "${file("${var.vm["SSH_KEY"]}")}"
    host        = "${element(var.IPV4_ADDRESS, count.index)}"
  }

  provisioner "remote-exec" {
    inline = [
      "echo  \"${element(var.IPV4_ADDRESS, count.index)} ${var.domain_cluster}\" >> /etc/hosts",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /etc/systemd/system/docker.service.d",
    ]
  }

  provisioner "file" {
    content     = "${data.template_file.override_conf.rendered}"
    destination = "/etc/systemd/system/docker.service.d/override.conf"
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

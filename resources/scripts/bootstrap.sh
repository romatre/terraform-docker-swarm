#!/bin/bash
apt-get update
apt-get -y install curl linux-image-extra-$(uname -r) linux-image-extra-virtual
apt-get install -y --no-install-recommends apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://apt.dockerproject.org/gpg | sudo apt-key add -
apt-key fingerprint 58118E89F3A912897C070ADBF76221572C52609D
apt-get install software-properties-common
add-apt-repository "deb https://apt.dockerproject.org/repo/ ubuntu-$(lsb_release -cs) main"
apt-get update
apt-get -y install docker-engine
groupadd docker
usermod -aG docker docker
mkdir -p /etc/systemd/system/docker.service.d/
mkdir -p /etc/docker/certs/

# AWS EC2 User Data - Docker Installation

## Overview

This guide provides an EC2 User Data script that installs Docker
automatically during instance launch.

## User Data Script

``` bash
#!/bin/bash
set -eux

apt update -y

apt install -y ca-certificates curl

install -m 0755 -d /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg   -o /etc/apt/keyrings/docker.asc

chmod a+r /etc/apt/keyrings/docker.asc

tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

apt update -y

apt install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin

systemctl enable docker
systemctl start docker

usermod -aG docker ubuntu

systemctl status docker --no-pager
docker --version
docker compose version
```

## Verify

``` bash
docker --version
docker compose version
systemctl status docker
```

If the current shell does not recognize Docker group membership:

``` bash
newgrp docker
```

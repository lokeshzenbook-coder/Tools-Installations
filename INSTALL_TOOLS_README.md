# AWS CLI, Docker, kubectl & eksctl Installation Script

## Overview

This repository provides a Bash script to automatically install the
following tools on an Ubuntu-based EC2 instance:

-   AWS CLI v2
-   eksctl
-   kubectl
-   Docker Engine
-   Docker Compose

The script updates the system, installs dependencies, validates each
installation, and logs progress to `/tmp/install.log`.

------------------------------------------------------------------------

## Repository Reference

Replace the placeholder below with your GitHub repository URL.

**Repository:**

``` text
https://github.com/<your-username>/<your-repository>
```

------------------------------------------------------------------------

## Installation Script

``` bash
#!/bin/bash

set -euo pipefail

LOG_FILE="/tmp/install.log"

log() {
    echo "$(date '+%F %T') - $1" | tee -a "$LOG_FILE"
}

if [[ $EUID -ne 0 ]]; then
    echo "Please run this script as root or with sudo."
    exit 1
fi

log "Updating package index..."

apt-get update -y
apt-get install -y \
    curl \
    unzip \
    tar \
    ca-certificates \
    gnupg \
    lsb-release

log "Installing AWS CLI..."

curl -sSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o awscliv2.zip
unzip -q awscliv2.zip
./aws/install --update
aws --version
rm -rf aws awscliv2.zip

ARCH=$(uname -m)
case "$ARCH" in
    x86_64) EKSCTL_ARCH="amd64" ;;
    aarch64|arm64) EKSCTL_ARCH="arm64" ;;
    *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

PLATFORM="$(uname -s)_${EKSCTL_ARCH}"

curl -sSL \
"https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_${PLATFORM}.tar.gz" \
-o eksctl.tar.gz

tar -xzf eksctl.tar.gz -C /tmp
install -m 0755 /tmp/eksctl /usr/local/bin/eksctl
rm -f eksctl.tar.gz /tmp/eksctl
eksctl version

case "$ARCH" in
    x86_64) KUBECTL_ARCH="amd64" ;;
    aarch64|arm64) KUBECTL_ARCH="arm64" ;;
esac

KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)

curl -LO \
"https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${KUBECTL_ARCH}/kubectl"

install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm -f kubectl
kubectl version --client

install -m 0755 -d /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
-o /etc/apt/keyrings/docker.asc

chmod a+r /etc/apt/keyrings/docker.asc

cat >/etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

apt-get update -y

apt-get install -y \
docker-ce \
docker-ce-cli \
containerd.io \
docker-buildx-plugin \
docker-compose-plugin

systemctl enable docker
systemctl start docker

echo "Installation completed successfully."
```

------------------------------------------------------------------------

## Usage

``` bash
chmod +x install-tools.sh
sudo ./install-tools.sh
```

## Log File

``` text
/tmp/install.log
```

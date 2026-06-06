#!/bin/bash

set -euo pipefail

LOG_FILE="/tmp/install.log"

log() {
echo "$(date '+%F %T') - $1" | tee -a "$LOG_FILE"
}

# Check root privileges

if [[ $EUID -ne 0 ]]; then
echo "Please run as root or sudo."
exit 1
fi

log "Installing prerequisites..."

apt update -y
apt install -y curl unzip tar ca-certificates gnupg

#########################################

# AWS CLI Installation

#########################################

log "Installing AWS CLI..."

curl -sSL 
"https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" 
-o awscliv2.zip

unzip -q awscliv2.zip

./aws/install --update

aws --version

rm -rf aws awscliv2.zip

log "AWS CLI installation completed."

#########################################

# eksctl Installation

#########################################

log "Installing eksctl..."

ARCH=$(uname -m | sed 's/x86_64/amd64/' | sed 's/aarch64/arm64/')
PLATFORM=$(uname -s)_${ARCH}

curl -sLO 
"https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_${PLATFORM}.tar.gz"

tar -xzf eksctl_${PLATFORM}.tar.gz -C /tmp

mv /tmp/eksctl /usr/local/bin

rm -f eksctl_${PLATFORM}.tar.gz

eksctl version

log "eksctl installation completed."

#########################################

# kubectl Installation

#########################################

log "Installing kubectl..."

curl -LO 
"https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${ARCH}/kubectl"

install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

rm -f kubectl

kubectl version --client

log "kubectl installation completed."

#########################################

# Docker Installation

#########################################

log "Installing Docker..."

install -m 0755 -d /etc/apt/keyrings

curl -fsSL 
https://download.docker.com/linux/ubuntu/gpg 
-o /etc/apt/keyrings/docker.asc

chmod a+r /etc/apt/keyrings/docker.asc

cat > /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

apt update -y

apt install -y 
docker-ce 
docker-ce-cli 
containerd.io 
docker-buildx-plugin 
docker-compose-plugin

systemctl enable docker
systemctl start docker

docker --version
docker compose version

log "Docker installation completed."

#########################################

# Validation

#########################################

echo ""
echo "=================================="
echo "Installed Versions"
echo "=================================="

aws --version
eksctl version
kubectl version --client
docker --version
docker compose version

echo ""
log "All tools installed successfully."

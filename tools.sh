#!/bin/bash

set -euo pipefail

LOG_FILE="/tmp/install.log"

echo "Installing AWS CLI..." | tee -a "$LOG_FILE"

curl -o awscliv2.zip \
https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip

unzip awscliv2.zip

sudo ./aws/install

aws --version

echo "Installation completed successfully."

# Set your architecture
ARCH=$(uname -m | sed 's/x86_64/amd64/' | sed 's/aarch64/arm64/')
PLATFORM=$(uname -s)_$ARCH

# Download and extract the archive
curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$PLATFORM.tar.gz"
tar -xzf "eksctl_$PLATFORM.tar.gz" -C /tmp

sudo mv /tmp/eksctl /usr/local/bin
eksctl version


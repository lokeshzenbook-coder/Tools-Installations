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


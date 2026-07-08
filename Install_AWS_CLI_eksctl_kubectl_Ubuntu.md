# Install AWS CLI, eksctl, and kubectl on Ubuntu

This guide installs the tools required to manage Amazon EKS clusters
from a Linux host.

## Prerequisites

``` bash
sudo apt update
sudo apt install -y curl unzip tar
```

------------------------------------------------------------------------

## Step 1: Install AWS CLI v2

Download and install AWS CLI:

``` bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt install -y unzip
unzip awscliv2.zip
sudo ./aws/install
```

Verify the installation:

``` bash
aws --version
```

------------------------------------------------------------------------

## Step 2: Install eksctl

Set your system architecture:

``` bash
ARCH=$(uname -m | sed 's/x86_64/amd64/' | sed 's/aarch64/arm64/')
PLATFORM=$(uname -s)_$ARCH
```

Download and install the latest release:

``` bash
curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$PLATFORM.tar.gz"
tar -xzf "eksctl_$PLATFORM.tar.gz" -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
```

Verify the installation:

``` bash
eksctl version
```

------------------------------------------------------------------------

## Step 3: Install kubectl

Download the latest stable release:

``` bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
```

Install it:

``` bash
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

Verify the installation:

``` bash
kubectl version --client
```

------------------------------------------------------------------------

# Official References

-   AWS CLI:
    https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
-   eksctl: https://eksctl.io/
-   eksctl GitHub: https://github.com/eksctl-io/eksctl
-   kubectl Installation:
    https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/
-   Amazon EKS User Guide:
    https://docs.aws.amazon.com/eks/latest/userguide/getting-started.html

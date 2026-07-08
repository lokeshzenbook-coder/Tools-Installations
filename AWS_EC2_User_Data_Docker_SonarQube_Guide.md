# AWS EC2 User Data Script -- Install Docker & Deploy SonarQube

> **Production-ready documentation** for provisioning an Ubuntu EC2
> instance with Docker and SonarQube using **AWS EC2 User Data**.

## 📋 Table of Contents

1.  Overview
2.  Architecture
3.  Prerequisites
4.  User Data Script
5.  Script Workflow
6.  Deployment Steps
7.  Verification
8.  Access SonarQube
9.  Troubleshooting
10. Cleanup
11. Security Recommendations

------------------------------------------------------------------------

# Overview

This EC2 User Data script automatically provisions a fresh Ubuntu
instance by:

-   ✅ Updating the operating system
-   ✅ Installing Docker Engine, Buildx, and Docker Compose
-   ✅ Configuring Docker's official repository
-   ✅ Enabling Docker at boot
-   ✅ Adding the `ubuntu` user to the Docker group
-   ✅ Deploying SonarQube Community Edition as a Docker container
-   ✅ Creating installation logs
-   ✅ Supporting complete cleanup

------------------------------------------------------------------------

# Architecture

``` text
AWS EC2 (Ubuntu)
        │
        ▼
Cloud-Init (User Data)
        │
        ▼
Install Docker
        │
        ▼
Start Docker Service
        │
        ▼
Pull SonarQube Image
        │
        ▼
Run Container (Port 9000)
        │
        ▼
Access via Browser
```

------------------------------------------------------------------------

# Prerequisites

-   Ubuntu 22.04 LTS or newer
-   EC2 instance (recommended: t3.medium or larger for SonarQube)
-   Security Group allowing:
    -   TCP 22 (SSH)
    -   TCP 9000 (SonarQube)
-   Internet access

------------------------------------------------------------------------

# User Data Script

> Paste your complete Bash User Data script here (unchanged from the
> original).

``` bash
#!/bin/bash
# (Use the script from this document)
```

------------------------------------------------------------------------

# Script Workflow

  Step   Description
  ------ ---------------------------------
  1      Update Ubuntu packages
  2      Install curl & CA certificates
  3      Add Docker GPG key
  4      Configure Docker repository
  5      Install Docker Engine
  6      Enable Docker service
  7      Add ubuntu user to Docker group
  8      Pull SonarQube image
  9      Start SonarQube container
  10     Save installation logs

------------------------------------------------------------------------

# Deploying the Script

1.  Launch an Ubuntu EC2 instance.
2.  Expand **Advanced Details**.
3.  Paste the User Data script.
4.  Configure the Security Group.
5.  Launch the instance.
6.  Wait 3--5 minutes for cloud-init to complete.

------------------------------------------------------------------------

# Verify Installation

``` bash
docker --version
docker compose version
docker ps
docker logs sonarqube-custom
```

Cloud-init logs:

``` bash
sudo cat /var/log/cloud-init-output.log
```

Success log:

``` bash
cat /var/log/user-data-success.log
```

------------------------------------------------------------------------

# Access SonarQube

Open:

``` text
http://<EC2-PUBLIC-IP>:9000
```

Default credentials:

  Username   Password
  ---------- ----------
  admin      admin

Change the password after the first login.

------------------------------------------------------------------------

# Troubleshooting

## Container not running

``` bash
docker ps -a
docker logs sonarqube-custom
```

## Docker service

``` bash
sudo systemctl status docker
```

## Cloud-init

``` bash
sudo journalctl -u cloud-init
```

------------------------------------------------------------------------

# Cleanup

``` bash
docker stop sonarqube-custom || true
docker rm sonarqube-custom || true
sudo systemctl stop docker
sudo apt remove -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo apt autoremove -y
sudo rm -rf /var/lib/docker /var/lib/containerd
sudo rm -f /etc/apt/sources.list.d/docker.sources
sudo rm -f /etc/apt/keyrings/docker.asc
```

------------------------------------------------------------------------

# Security Recommendations

-   Use an Elastic IP for stable access.
-   Restrict port **9000** to trusted IP ranges.
-   Use HTTPS with a reverse proxy (NGINX/ALB) in production.
-   Store SonarQube data in persistent volumes.
-   Regularly update Docker images.
-   Replace default credentials immediately.

------------------------------------------------------------------------

# Notes

-   Compatible with Ubuntu 22.04+.
-   Intended for AWS EC2 User Data automation.
-   Docker starts automatically after reboot.
-   SonarQube runs using the Community Edition container.

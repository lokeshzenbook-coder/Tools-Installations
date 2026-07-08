# Install Docker and Run SonarQube on Ubuntu

This guide installs Docker Engine from Docker's official APT repository
and runs SonarQube in a Docker container.

## Prerequisites

Update package index and install required packages:

``` bash
sudo apt update
sudo apt install -y ca-certificates curl
```

------------------------------------------------------------------------

## Step 1: Add Docker's Official GPG Key

``` bash
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
```

------------------------------------------------------------------------

## Step 2: Add Docker Repository

``` bash
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF
```

Update package information:

``` bash
sudo apt update -y
```

------------------------------------------------------------------------

## Step 3: Install Docker Engine

``` bash
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

------------------------------------------------------------------------

## Step 4: Verify Docker Installation

Check Docker service:

``` bash
sudo systemctl status docker
```

Check Docker version:

``` bash
docker --version
```

------------------------------------------------------------------------

## Step 5: Allow Non-root Docker Access

Add your user to the Docker group:

``` bash
sudo usermod -aG docker $USER
```

Apply the new group membership:

``` bash
newgrp docker
```

Verify:

``` bash
groups
```

------------------------------------------------------------------------

## Step 6: Run SonarQube as a Docker Container

Start SonarQube Community Edition:

``` bash
docker run -d \
  --name sonarqube-custom \
  --restart unless-stopped \
  -p 9000:9000 \
  sonarqube:10.6-community
```

Verify the container:

``` bash
docker ps
```

Access SonarQube:

    http://<SERVER-IP>:9000

Default credentials:

-   Username: `admin`
-   Password: `admin`

You will be prompted to change the password on first login.

------------------------------------------------------------------------

# References

-   Docker Engine Installation (Ubuntu):
    https://docs.docker.com/engine/install/ubuntu/
-   Docker Engine Documentation: https://docs.docker.com/engine/
-   SonarQube Docker Image: https://hub.docker.com/\_/sonarqube
-   SonarQube Documentation: https://docs.sonarsource.com/sonarqube/

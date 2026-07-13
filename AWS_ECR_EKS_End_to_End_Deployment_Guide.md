# End-to-End Deployment Guide: AWS ECR + Amazon EKS

## Overview

This guide explains how to build, test, publish, and deploy a
containerized application to Amazon EKS using Amazon ECR as the
container registry.

## Architecture Workflow

``` text
Application Source Code
        │
        ▼
Git Clone
        │
        ▼
Build Docker Image
        │
        ▼
Test Docker Image Locally
        │
        ▼
Authenticate to AWS
        │
        ▼
Push Image to Amazon ECR
        │
        ▼
Create / Update Amazon EKS Cluster
        │
        ▼
Configure kubectl
        │
        ▼
Create Namespace
        │
        ▼
Create ConfigMaps / Secrets
        │
        ▼
Deploy Kubernetes Manifests (or Helm)
        │
        ▼
Verify Deployments & Pods
        │
        ▼
Expose Application (ALB / NLB / Ingress)
        │
        ▼
Access Application
        │
        ▼
Scale / Rolling Updates / Rollback
        │
        ▼
Monitor & Observe
```

## Prerequisites

-   AWS Account
-   AWS CLI configured
-   Docker
-   kubectl
-   eksctl or Terraform
-   IAM permissions
-   Amazon ECR repository
-   Amazon EKS cluster

------------------------------------------------------------------------

# Step 1: Clone Repository

``` bash
git clone https://github.com/lokeshzenbook-coder/cloudkitchen-app.git
cd cloudkitchen-app
```

------------------------------------------------------------------------

# Step 2: Build Docker Images

``` bash
docker build -t auth-service:latest ./auth-service
```

Or:

``` bash
./scripts/build-images.sh
```

Verify:

``` bash
docker images
```

------------------------------------------------------------------------

# Step 3: Test Locally

``` bash
docker run -d --name auth -p 8080:8080 auth-service:latest
docker ps
```

------------------------------------------------------------------------

# Step 4: Create an Amazon ECR Repository

``` bash
aws ecr create-repository --repository-name auth-service
```

Repeat for each microservice or automate with Terraform.

------------------------------------------------------------------------

# Step 5: Authenticate Docker to Amazon ECR

``` bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com
```

------------------------------------------------------------------------

# Step 6: Tag and Push Images

``` bash
docker tag auth-service:latest <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/auth-service:latest

docker push <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/auth-service:latest
```

Repeat for all services.

------------------------------------------------------------------------

# Step 7: Create an Amazon EKS Cluster

Using eksctl:

``` bash
eksctl create cluster --name cloudkitchen --region us-east-1 --nodes 3
```

Or provision the cluster with Terraform.

------------------------------------------------------------------------

# Step 8: Configure kubectl

``` bash
aws eks update-kubeconfig --region us-east-1 --name cloudkitchen
```

Verify:

``` bash
kubectl get nodes
```

------------------------------------------------------------------------

# Step 9: Create Namespace

``` bash
kubectl create namespace cloudkitchen
```

------------------------------------------------------------------------

# Step 10: Update Kubernetes Deployment

Example image:

``` yaml
image: <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/auth-service:latest
```

Unlike private Docker Hub, EKS nodes with the correct IAM permissions
can pull from ECR without creating a Docker registry secret.

------------------------------------------------------------------------

# Step 11: Deploy

``` bash
kubectl apply -f k8s/
```

or

``` bash
helm install cloudkitchen ./helm/cloudkitchen -n cloudkitchen
```

------------------------------------------------------------------------

# Step 12: Verify

``` bash
kubectl get pods -n cloudkitchen
kubectl get deployments -n cloudkitchen
kubectl get svc -n cloudkitchen
```

------------------------------------------------------------------------

# Step 13: Check Logs

``` bash
kubectl logs <pod-name> -n cloudkitchen
```

------------------------------------------------------------------------

# Step 14: Expose the Application

Install the AWS Load Balancer Controller, then create an Ingress or use
a Service of type LoadBalancer.

``` bash
kubectl get ingress -n cloudkitchen
```

or

``` bash
kubectl get svc -n cloudkitchen
```

------------------------------------------------------------------------

# Step 15: Scale

``` bash
kubectl scale deployment auth-service --replicas=5 -n cloudkitchen
```

------------------------------------------------------------------------

# Step 16: Rolling Update

``` bash
docker build -t auth-service:v2 ./auth-service

docker tag auth-service:v2 <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/auth-service:v2

docker push <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/auth-service:v2

kubectl set image deployment/auth-service auth-service=<ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/auth-service:v2 -n cloudkitchen
```

------------------------------------------------------------------------

# Step 17: Rollback

``` bash
kubectl rollout undo deployment/auth-service -n cloudkitchen
```

------------------------------------------------------------------------

# Step 18: Monitor

``` bash
kubectl top nodes
kubectl top pods -n cloudkitchen
```

Recommended production tooling:

-   Metrics Server
-   Prometheus
-   Grafana
-   CloudWatch Container Insights

------------------------------------------------------------------------

# Step 19: Clean Up

Delete application:

``` bash
kubectl delete -f k8s/
```

Delete namespace:

``` bash
kubectl delete namespace cloudkitchen
```

Delete EKS cluster:

``` bash
eksctl delete cluster --name cloudkitchen
```

Delete ECR repository:

``` bash
aws ecr delete-repository --repository-name auth-service --force
```

## CI/CD Pipeline

``` text
Developer
   │
   ▼
GitHub
   │
   ▼
GitHub Actions
   │
   ├── Gitleaks
   ├── Hadolint
   ├── Trivy
   ├── Build Images
   ├── Push to Amazon ECR
   ▼
Amazon ECR
   │
   ▼
Amazon EKS
   │
   ▼
AWS Load Balancer Controller
   │
   ▼
Application
```

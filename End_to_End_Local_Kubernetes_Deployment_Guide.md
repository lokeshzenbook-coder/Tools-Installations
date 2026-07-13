# End-to-End Deployment of a Containerized Application to a Local Kubernetes Cluster

## Overview

This guide explains how to build Docker images, push them to Docker Hub,
and deploy them to a local multi-node Kubernetes cluster.

## Deployment Workflow

``` text
Application Source Code
        │
        ▼
Build Docker Image
        │
        ▼
Test Docker Image Locally
        │
        ▼
Push Image to Docker Hub
        │
        ▼
Create Kubernetes Manifests
        │
        ▼
Create Namespace
        │
        ▼
Create Secrets (if needed)
        │
        ▼
Deploy to Kubernetes
        │
        ▼
Verify Pods
        │
        ▼
Expose Application
        │
        ▼
Access Application
```

## Prerequisites

-   Docker
-   Kubernetes cluster
-   kubectl
-   Docker Hub account
-   Git

## Step 1: Clone the Repository

``` bash
git clone https://github.com/lokeshzenbook-coder/cloudkitchen-app.git
cd cloudkitchen-app
```

## Step 2: Build Docker Images

``` bash
docker build -t lokeshzenbook/auth-service:latest ./auth-service
```

Or:

``` bash
./scripts/build-images.sh
```

Verify:

``` bash
docker images
```

## Step 3: Test the Image

``` bash
docker run -d --name auth -p 8080:8080 lokeshzenbook/auth-service:latest
docker ps
```

## Step 4: Push to Docker Hub

``` bash
docker login
docker push lokeshzenbook/auth-service:latest
docker push lokeshzenbook/user-service:latest
```

## Step 5: Verify Kubernetes

``` bash
kubectl get nodes
```

## Step 6: Create Namespace

``` bash
kubectl create namespace cloudkitchen
kubectl get ns
```

## Step 7: Create Docker Hub Pull Secret (Private Repositories)

``` bash
kubectl create secret docker-registry dockerhub-secret   --docker-server=https://index.docker.io/v1/   --docker-username=<dockerhub-username>   --docker-password=<dockerhub-token>   --docker-email=<email>   -n cloudkitchen
```

## Step 8: Create Deployment

Use a Deployment that references your Docker Hub image and
`imagePullSecrets` if your repository is private.

## Step 9: Create a Service

Create a `ClusterIP`, `NodePort`, or `LoadBalancer` Service depending on
your environment.

## Step 10: Deploy

``` bash
kubectl apply -f k8s/
```

## Step 11: Verify

``` bash
kubectl get pods -n cloudkitchen
kubectl get deployments -n cloudkitchen
kubectl get svc -n cloudkitchen
```

## Step 12: Logs

``` bash
kubectl logs <pod-name> -n cloudkitchen
```

## Step 13: Troubleshooting

``` bash
kubectl describe pod <pod-name> -n cloudkitchen
```

Common issues:

-   ImagePullBackOff
-   CrashLoopBackOff
-   Pending

## Step 14: Expose the Frontend

Use a NodePort or Ingress.

``` bash
kubectl get svc -n cloudkitchen
```

## Step 15: Scale

``` bash
kubectl scale deployment auth-service --replicas=5 -n cloudkitchen
kubectl get pods -o wide -n cloudkitchen
```

## Step 16: Rolling Update

``` bash
docker build -t lokeshzenbook/auth-service:v2 ./auth-service
docker push lokeshzenbook/auth-service:v2

kubectl set image deployment/auth-service auth-service=lokeshzenbook/auth-service:v2 -n cloudkitchen

kubectl rollout status deployment/auth-service -n cloudkitchen
```

## Step 17: Rollback

``` bash
kubectl rollout undo deployment/auth-service -n cloudkitchen
```

## Step 18: Monitor

``` bash
kubectl top nodes
kubectl top pods -n cloudkitchen
```

## Step 19: Clean Up

``` bash
kubectl delete -f k8s/
kubectl delete namespace cloudkitchen
```

## Summary

This workflow demonstrates building, testing, publishing, deploying,
verifying, scaling, updating, monitoring, and cleaning up a
containerized application on a local Kubernetes cluster.

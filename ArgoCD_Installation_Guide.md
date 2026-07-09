# Argo CD Installation Guide for Amazon EKS

## Overview

This document provides a reference for installing Argo CD on Amazon EKS,
exposing the UI with a LoadBalancer, troubleshooting common issues, and
useful reference links.

------------------------------------------------------------------------

# Prerequisites

-   Kubernetes cluster (Amazon EKS)
-   kubectl configured
-   AWS CLI
-   eksctl (optional)
-   Helm (optional)

Verify access:

``` bash
kubectl get nodes
```

------------------------------------------------------------------------

# Install Argo CD

Create the namespace:

``` bash
kubectl create namespace argocd
```

Install Argo CD:

``` bash
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

Verify:

``` bash
kubectl get pods -n argocd
```

------------------------------------------------------------------------

# Expose the Argo CD UI

Change the service type:

``` bash
kubectl patch svc argocd-server \
  -n argocd \
  -p '{"spec":{"type":"LoadBalancer"}}'
```

Check the external endpoint:

``` bash
kubectl get svc argocd-server -n argocd
```

------------------------------------------------------------------------

# Retrieve the Initial Admin Password

``` bash
kubectl -n argocd get secret argocd-initial-admin-secret \
-o jsonpath="{.data.password}" | base64 -d
```

Username:

``` text
admin
```

------------------------------------------------------------------------

# Login

``` bash
argocd login <LOAD_BALANCER_DNS>
```

------------------------------------------------------------------------

# Troubleshooting

## Pods not running

``` bash
kubectl get pods -n argocd
kubectl describe pod <pod-name> -n argocd
kubectl logs <pod-name> -n argocd
```

## LoadBalancer pending

``` bash
kubectl get svc -n argocd
```

Verify: - AWS Load Balancer Controller (if required) - Public subnets
tagged for ELB - Security groups - IAM permissions

## Cannot access the UI

-   Verify the LoadBalancer DNS name.
-   Confirm inbound HTTPS (443) is allowed.
-   Check `argocd-server` service and pod status.

------------------------------------------------------------------------

# Useful Commands

``` bash
kubectl get all -n argocd
kubectl get svc -n argocd
kubectl logs deployment/argocd-server -n argocd
kubectl rollout restart deployment argocd-server -n argocd
```

------------------------------------------------------------------------

# Repository Reference

Replace this placeholder with your GitHub repository URL.

``` text
https://github.com/<your-username>/<your-repository>
```

Store installation scripts, manifests, and documentation in your
repository for future reference.

------------------------------------------------------------------------

# Official References

-   Argo CD Documentation: https://argo-cd.readthedocs.io/
-   Argo CD GitHub: https://github.com/argoproj/argo-cd
-   Amazon EKS Documentation: https://docs.aws.amazon.com/eks/
-   Kubernetes Documentation: https://kubernetes.io/docs/

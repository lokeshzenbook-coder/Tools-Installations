# Integrating an AWS EKS Cluster with Lens (Kubernetes IDE)

## Overview

Yes, **AWS EKS clusters can be integrated with Lens**, one of the most
popular Kubernetes desktop IDEs. Lens connects to Kubernetes clusters
using your local **kubeconfig** file, making EKS management simple and
visual.

------------------------------------------------------------------------

## Architecture

``` text
                    AWS Account
                         │
                  Amazon EKS Cluster
                         │
               AWS IAM Authentication
                         │
                 kubeconfig (~/.kube/config)
                         │
                    kubectl Access
                         │
                    Lens Desktop
```

------------------------------------------------------------------------

# Prerequisites

-   AWS CLI installed
-   kubectl installed
-   Lens Desktop installed
-   IAM user or IAM role with access to the EKS cluster
-   kubeconfig configured

------------------------------------------------------------------------

# Step 1 -- Configure AWS Credentials

``` bash
aws configure
```

Verify the authenticated identity:

``` bash
aws sts get-caller-identity
```

Example:

``` json
{
  "Account": "123456789012",
  "Arn": "arn:aws:iam::123456789012:user/devops"
}
```

------------------------------------------------------------------------

# Step 2 -- Update kubeconfig

``` bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name my-cluster
```

Example:

``` bash
aws eks update-kubeconfig \
  --region ap-south-1 \
  --name production-eks
```

------------------------------------------------------------------------

# Step 3 -- Verify Cluster Access

List contexts:

``` bash
kubectl config get-contexts
```

Check nodes:

``` bash
kubectl get nodes
```

------------------------------------------------------------------------

# Step 4 -- Install Lens

Download and install Lens Desktop for your operating system.

------------------------------------------------------------------------

# Step 5 -- Connect Lens

Lens automatically detects:

``` text
~/.kube/config
```

Select your EKS cluster and connect.

------------------------------------------------------------------------

# Features Available in Lens

-   Namespaces
-   Nodes
-   Pods
-   Deployments
-   StatefulSets
-   DaemonSets
-   Services
-   Ingresses
-   ConfigMaps
-   Secrets
-   Jobs & CronJobs
-   Pod Logs
-   Terminal (kubectl exec)
-   YAML Editor
-   Helm Releases
-   Metrics (requires Metrics Server)

------------------------------------------------------------------------

# Working with Multiple EKS Clusters

``` bash
aws eks update-kubeconfig --region ap-south-1 --name dev-cluster
aws eks update-kubeconfig --region ap-south-1 --name staging-cluster
aws eks update-kubeconfig --region ap-south-1 --name production-cluster
```

Switch contexts:

``` bash
kubectl config use-context arn:aws:eks:ap-south-1:111111111111:cluster/dev-cluster
```

------------------------------------------------------------------------

# Troubleshooting

## Check Current Context

``` bash
kubectl config current-context
```

## Verify Cluster

``` bash
kubectl get nodes
```

## Refresh kubeconfig

``` bash
aws eks update-kubeconfig \
  --region ap-south-1 \
  --name production-eks
```

## Verify IAM Permissions

Ensure your IAM identity has permissions such as:

-   `eks:DescribeCluster`
-   `eks:ListClusters`

Your IAM identity must also be authorized within the EKS cluster.

------------------------------------------------------------------------

# Private EKS Clusters

For clusters with private API endpoints, ensure network connectivity
through one of the following:

-   VPN
-   AWS Client VPN
-   AWS Systems Manager Session Manager (SSM)
-   Bastion Host
-   AWS Direct Connect

------------------------------------------------------------------------

# Useful Commands

``` bash
kubectl cluster-info
kubectl get nodes
kubectl get pods -A

aws eks describe-cluster \
  --name production-eks \
  --region ap-south-1

kubectl config view
```

------------------------------------------------------------------------

# Common Errors

  ------------------------------------------------------------------------
  Error                  Cause               Solution
  ---------------------- ------------------- -----------------------------
  Unauthorized           IAM identity not    Grant EKS access
                         authorized          

  Connection refused     Network or endpoint Verify VPC connectivity
                         issue               

  No cluster found       Wrong cluster name  Run `aws eks list-clusters`

  Context not found      Missing kubeconfig  Run
                                             `aws eks update-kubeconfig`

  Expired token          Temporary           Re-authenticate to AWS
                         credentials expired 
  ------------------------------------------------------------------------

------------------------------------------------------------------------

# Best Practices

-   Keep AWS CLI and kubectl updated.
-   Use IAM roles and least-privilege permissions.
-   Enable Metrics Server for monitoring.
-   Manage multiple clusters using contexts.
-   Verify kubectl connectivity before opening Lens.

------------------------------------------------------------------------

# Conclusion

Lens provides an intuitive graphical interface for managing Amazon EKS
clusters. As long as your `kubectl` access works and your `kubeconfig`
is configured correctly, Lens can securely connect to your EKS cluster
and simplify day-to-day Kubernetes operations.

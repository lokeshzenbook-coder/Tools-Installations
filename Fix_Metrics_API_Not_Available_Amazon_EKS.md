# Fix `error: Metrics API not available` (Amazon EKS)

This guide provides a quick troubleshooting workflow for resolving the
Kubernetes error:

``` bash
error: Metrics API not available
```

## Step 1: Verify the error

``` bash
kubectl top nodes
```

------------------------------------------------------------------------

## Step 2: Check whether Metrics Server is installed

``` bash
kubectl get deployment metrics-server -n kube-system
kubectl get pods -n kube-system | grep metrics
```

------------------------------------------------------------------------

## Step 3: Install Metrics Server

``` bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

Verify the installation:

``` bash
kubectl get pods -n kube-system
```

------------------------------------------------------------------------

## Step 4: Check Metrics Server logs

``` bash
kubectl logs -n kube-system deployment/metrics-server
```

------------------------------------------------------------------------

## Step 5: For Minikube, Kind, Kubeadm, or Lab Clusters

Edit the Metrics Server deployment:

``` bash
kubectl edit deployment metrics-server -n kube-system
```

Add the following argument under `args`:

``` yaml
- --kubelet-insecure-tls
```

Restart the deployment:

``` bash
kubectl rollout restart deployment metrics-server -n kube-system
```

> **Note:** `--kubelet-insecure-tls` is intended for development or lab
> environments. Avoid using it in production unless necessary.

------------------------------------------------------------------------

## Step 6: Verify the Metrics API

``` bash
kubectl get apiservices | grep metrics
```

Expected output:

``` text
v1beta1.metrics.k8s.io   True
```

------------------------------------------------------------------------

## Step 7: Verify Metrics

``` bash
kubectl top nodes
kubectl top pods -A
```

If metrics are displayed, the issue has been resolved.

------------------------------------------------------------------------

# References

-   Metrics Server GitHub Repository:
    https://github.com/kubernetes-sigs/metrics-server
-   Installation Manifest:
    https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
-   Kubernetes Metrics Server Documentation:
    https://github.com/kubernetes-sigs/metrics-server/blob/master/README.md
-   Kubernetes Resource Metrics Pipeline:
    https://kubernetes.io/docs/tasks/debug/debug-cluster/resource-metrics-pipeline/

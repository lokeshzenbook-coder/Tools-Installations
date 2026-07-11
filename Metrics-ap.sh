#!/bin/bash

set -euo pipefail

echo "========================================="
echo " Installing Kubernetes Metrics Server"
echo "========================================="

# Check kubectl
if ! command -v kubectl &>/dev/null; then
    echo "kubectl is not installed."
    exit 1
fi

echo "Checking cluster connectivity..."
kubectl cluster-info >/dev/null

echo "Installing Metrics Server..."
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

echo "Waiting for deployment to be created..."
sleep 10

echo "Patching Metrics Server deployment..."

kubectl patch deployment metrics-server \
  -n kube-system \
  --type='json' \
  -p='[
    {
      "op":"add",
      "path":"/spec/template/spec/containers/0/args/-",
      "value":"--kubelet-insecure-tls"
    },
    {
      "op":"add",
      "path":"/spec/template/spec/containers/0/args/-",
      "value":"--kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname"
    },
    {
      "op":"add",
      "path":"/spec/template/spec/containers/0/args/-",
      "value":"--kubelet-use-node-status-port"
    }
  ]'

echo "Restarting deployment..."
kubectl rollout restart deployment metrics-server -n kube-system

echo "Waiting for Metrics Server to become Ready..."
kubectl rollout status deployment metrics-server -n kube-system --timeout=300s

echo "Waiting for metrics to be collected..."
sleep 30

echo
echo "Metrics Server Pods:"
kubectl get pods -n kube-system -l app.kubernetes.io/name=metrics-server

echo
echo "APIService:"
kubectl get apiservice v1beta1.metrics.k8s.io

echo
echo "Node Metrics:"
kubectl top nodes

echo
echo "Pod Metrics:"
kubectl top pods -A

echo
echo "========================================="
echo " Metrics Server Installed Successfully"
echo "========================================="

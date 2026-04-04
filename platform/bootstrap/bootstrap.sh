#!/usr/bin/env bash
set -euo pipefail

# Bootstrap script for the OSS Summit 2026 platform engineering demo.
# Run this once against the base LKE cluster.
# Prerequisites: kubectl configured with kubeconfig.yaml, helm v3, OSS_LINODE_API_TOKEN set.

: "${OSS_LINODE_API_TOKEN:?OSS_LINODE_API_TOKEN must be set}"

echo "==> Adding Helm repos"
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

echo "==> Installing ArgoCD"
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
helm upgrade --install argocd argo/argo-cd \
  --namespace argocd \
  --version 9.4.17 \
  --values platform/bootstrap/argocd/values.yaml \
  --wait

echo "==> Creating Linode credentials secret (Crossplane)"
kubectl create namespace crossplane-system --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret generic linode-credentials \
  --namespace crossplane-system \
  --from-literal=credentials="{\"token\":\"${OSS_LINODE_API_TOKEN}\"}" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "==> Creating Linode token secret (external-dns)"
kubectl create namespace external-dns --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret generic linode-token \
  --namespace external-dns \
  --from-literal=token="${OSS_LINODE_API_TOKEN}" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "==> Creating Grafana admin secret (random password)"
kubectl create namespace o11y --dry-run=client -o yaml | kubectl apply -f -
GRAFANA_PASSWORD=$(openssl rand -base64 32 | tr -d '=+/' | head -c 32)
kubectl create secret generic grafana-admin-secret \
  --namespace o11y \
  --from-literal=admin-user=admin \
  --from-literal=admin-password="${GRAFANA_PASSWORD}" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "==> Applying App of Apps (ArgoCD will manage all platform apps)"
kubectl apply -f platform/bootstrap/app-of-apps.yaml

echo ""
echo "Bootstrap complete. ArgoCD will now reconcile all platform services."
echo ""
ARGOCD_IP=$(kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "<pending>")
echo "ArgoCD UI:  http://${ARGOCD_IP}"
echo "Username:   admin"
echo "Password:   $(kubectl get secret argocd-initial-admin-secret -n argocd \
  -o jsonpath='{.data.password}' 2>/dev/null | base64 -d 2>/dev/null || echo '<run: kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath={.data.password} | base64 -d>')"
echo ""
echo "Grafana password: ${GRAFANA_PASSWORD}"
echo ""
echo "Monitor sync status:"
echo "  kubectl get applications -A"

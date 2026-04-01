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

echo "==> Creating Linode credentials secret"
kubectl create namespace crossplane-system --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret generic linode-credentials \
  --namespace crossplane-system \
  --from-literal=credentials="{\"token\":\"${OSS_LINODE_API_TOKEN}\"}" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "==> Applying ArgoCD Applications"
kubectl apply -f platform/apps/crossplane.yaml
kubectl apply -f platform/apps/crossplane-providers.yaml
kubectl apply -f platform/apps/o11y.yaml
kubectl apply -f platform/apps/kro.yaml
kubectl apply -f platform/apps/score.yaml

echo ""
echo "Bootstrap complete. ArgoCD will now reconcile all platform services."
echo ""
ARGOCD_IP=$(kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "<pending>")
echo "ArgoCD UI: http://${ARGOCD_IP}"
echo "Username:  admin"
echo "Password:  admin"
echo ""
echo "Monitor sync status:"
echo "  kubectl get applications -A"

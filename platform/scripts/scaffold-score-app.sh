#!/usr/bin/env bash

set -euo pipefail

usage() {
  echo "usage: $0 <app> [image]"
}

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
  usage >&2
  exit 1
fi

app="$1"
image="${2:-nginx:1.27}"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
workload_dir="$repo_root/platform/workloads/apps/$app"

if [ -e "$workload_dir" ]; then
  echo "app already exists: $app" >&2
  exit 1
fi

mkdir -p "$workload_dir/rendered"

cat > "$workload_dir/score.yaml" <<EOF
apiVersion: score.dev/v1b1
metadata:
  name: $app

containers:
  $app:
    image: $image
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        cpu: 250m
        memory: 256Mi
    livenessProbe:
      httpGet:
        path: /
        port: 80
    readinessProbe:
      httpGet:
        path: /
        port: 80

service:
  ports:
    http:
      port: 80
      targetPort: 80
EOF

cat > "$workload_dir/rendered/namespace.yaml" <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: $app
EOF

cat > "$workload_dir/rendered/gateway.yaml" <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: default
  namespace: $app
spec:
  gatewayClassName: nginx
  listeners:
    - name: web
      protocol: HTTP
      port: 8000
EOF

if command -v score-k8s >/dev/null 2>&1; then
  "$repo_root/platform/scripts/render-score-app.sh" "$app"
else
  echo "created $app"
  echo "ensure the target PlatformCluster includes $app under spec.components.userApps.enabled"
  echo "next: score-k8s install, then run platform/scripts/render-score-app.sh $app"
fi

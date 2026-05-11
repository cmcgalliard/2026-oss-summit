#!/usr/bin/env bash

set -euo pipefail

usage() {
  echo "usage: $0 <app>"
}

if [ "$#" -ne 1 ]; then
  usage >&2
  exit 1
fi

app="$1"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
workload_dir="$repo_root/platform/workloads/apps/$app"
namespace="$app"

if ! command -v score-k8s >/dev/null 2>&1; then
  echo "score-k8s is required" >&2
  exit 1
fi

if [ ! -f "$workload_dir/score.yaml" ]; then
  echo "missing Score file: $workload_dir/score.yaml" >&2
  exit 1
fi

mkdir -p "$workload_dir/rendered"

cat > "$workload_dir/rendered/namespace.yaml" <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: $namespace
EOF

cat > "$workload_dir/rendered/gateway.yaml" <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: default
  namespace: $namespace
spec:
  gatewayClassName: traefik
  listeners:
    - name: web
      protocol: HTTP
      port: 8000
EOF

(
  cd "$workload_dir"
  score-k8s init --no-sample >/dev/null
  score-k8s generate score.yaml --namespace "$namespace" -o rendered/manifests.yaml >/dev/null
)

echo "rendered $app"

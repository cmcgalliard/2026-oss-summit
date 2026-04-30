#!/usr/bin/env bash

set -euo pipefail

usage() {
  echo "usage: $0 <cluster> <app>"
}

if [ "$#" -ne 2 ]; then
  usage >&2
  exit 1
fi

cluster="$1"
app="$2"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
workload_dir="$repo_root/platform/workloads/$cluster/$app"
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

(
  cd "$workload_dir"
  score-k8s init --no-sample >/dev/null
  score-k8s generate score.yaml --namespace "$namespace" -o rendered/manifests.yaml >/dev/null
)

echo "rendered $cluster/$app"

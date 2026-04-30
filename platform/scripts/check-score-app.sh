#!/usr/bin/env bash

set -euo pipefail

usage() {
  echo "usage: $0 [<cluster> <app>]"
}

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

if ! command -v score-k8s >/dev/null 2>&1; then
  echo "score-k8s is required" >&2
  exit 1
fi

workloads=()
generated_files=()
if [ "$#" -eq 0 ]; then
  while IFS= read -r score_file; do
    workloads+=("${score_file%/score.yaml}")
  done < <(find "$repo_root/platform/workloads" -mindepth 3 -maxdepth 3 -type f -name score.yaml | sort)
elif [ "$#" -eq 2 ]; then
  workloads+=("$repo_root/platform/workloads/$1/$2")
else
  usage >&2
  exit 1
fi

if [ "${#workloads[@]}" -eq 0 ]; then
  echo "no workloads found" >&2
  exit 1
fi

for workload_dir in "${workloads[@]}"; do
  cluster="$(basename "$(dirname "$workload_dir")")"
  app="$(basename "$workload_dir")"
  rendered_dir="$workload_dir/rendered"

  [ -f "$workload_dir/score.yaml" ] || { echo "missing $workload_dir/score.yaml" >&2; exit 1; }
  [ -f "$rendered_dir/namespace.yaml" ] || { echo "missing $rendered_dir/namespace.yaml" >&2; exit 1; }
  [ -f "$rendered_dir/manifests.yaml" ] || { echo "missing $rendered_dir/manifests.yaml" >&2; exit 1; }

  "$repo_root/platform/scripts/render-score-app.sh" "$cluster" "$app"
  generated_files+=("$rendered_dir/namespace.yaml")
  generated_files+=("$rendered_dir/manifests.yaml")
done

git -C "$repo_root" diff --exit-code -- "${generated_files[@]}"

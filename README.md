# OSS Summit 2026 Platform Demo

GitOps-managed platform for an Akamai Cloud Linode Kubernetes Engine cluster. This repository bootstraps Argo CD and lets Argo CD manage the rest of the platform from git.

## What This Repo Does

- Bootstraps Argo CD into a base LKE cluster
- Uses an app-of-apps pattern to reconcile `platform/apps/`
- Installs core platform services for ingress, DNS, TLS, observability, and infrastructure provisioning
- Publishes a KRO-backed `PlatformCluster` API for provisioning additional LKE clusters
- Keeps cluster configuration in git so changes are applied declaratively

## Platform Components

- `Argo CD`: GitOps controller and app-of-apps entrypoint
- `cert-manager`: Let's Encrypt certificate management
- `Traefik`: default ingress controller exposed as `LoadBalancer`
- `external-dns`: Linode DNS automation for `ossdemo.soupcan.io`
- `Crossplane`: infrastructure provisioning, including Linode provider support
- `Grafana`, `Loki`, `Tempo`: observability stack
- `KRO`: Kubernetes Resource Orchestrator
- `PlatformCluster`: KRO resource graph for self-service cluster provisioning
- `Score`: example workload specification under `platform/score/`

## Repository Layout

```text
platform/
  apps/         Argo CD Application manifests
  bootstrap/    One-time cluster bootstrap assets
  cert-manager/ ClusterIssuer manifests
  crd/          Synced KRO ResourceGraphDefinitions
  crossplane/   Provider and provider config manifests
  examples/     Manual-only PlatformCluster examples
  helm/         Helm values files by service
  score/        Example Score workload manifests
```

## Prerequisites

- A working LKE cluster and local `kubeconfig.yaml`
- `kubectl`
- `helm` v3
- `openssl`
- `OSS_LINODE_API_TOKEN` exported in your shell
- `OSS_GITHUB_DEPLOY_KEY_PATH` exported in your shell, pointing to an SSH deploy key with access to this repository

## Bootstrap

Run the bootstrap script once against the base cluster:

```bash
export OSS_LINODE_API_TOKEN="<your-token>"
export OSS_GITHUB_DEPLOY_KEY_PATH="/path/to/id_ed25519"
bash platform/bootstrap/bootstrap.sh
```

The bootstrap script:

- installs Argo CD
- creates the Linode and Grafana bootstrap secrets
- registers the GitHub repo in Argo CD using the SSH key at `OSS_GITHUB_DEPLOY_KEY_PATH`
- applies `platform/bootstrap/app-of-apps.yaml`

After that, Argo CD reconciles everything in `platform/apps/`.

## Secrets And Credentials

- `argocd-initial-admin-secret`: auto-generated Argo CD admin password
- `grafana-admin-secret`: random password generated during bootstrap
- `linode-credentials`: Crossplane Linode credentials
- `linode-token`: external-dns Linode API token

Retrieve credentials with `kubectl`:

```bash
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 -d && echo
kubectl get secret grafana-admin-secret -n o11y -o jsonpath='{.data.admin-password}' | base64 -d && echo
```

## Sync Order

```text
Wave 0: bootstrap Argo CD and imperative secrets
Wave 1: cert-manager, crossplane
Wave 2: traefik, crossplane-providers
Wave 3: kro, o11y, external-dns, score
Wave 4: cert-manager-issuers
Wave 5: platform-crd
```

`platform-crd` syncs `platform/crd/platformcluster-rgd.yaml` into `kro-system` after KRO is already present.

## PlatformCluster

The app-of-apps bootstrap only watches `platform/apps/`, so the live `PlatformCluster` `ResourceGraphDefinition` is stored in `platform/crd/` and reconciled by `platform/apps/platform-crd.yaml`.

Example `PlatformCluster` manifests live under `platform/examples/` and are applied manually so Argo CD does not auto-create demo clusters:

```bash
kubectl get application platform-crd -n argocd
kubectl explain platformcluster
kubectl apply -f platform/examples/dev-cluster.yaml
```

See `platform/README.md` for the schema, prerequisites, and usage flow.

## Day-2 Changes

- Add or update Argo CD apps in `platform/apps/`
- Tune chart configuration in `platform/helm/`
- Update platform manifests in `platform/cert-manager/`, `platform/crossplane/`, `platform/crd/`, or `platform/score/`
- Apply or update manual examples in `platform/examples/` when testing `PlatformCluster`
- Commit and push changes so Argo CD can reconcile them

## Verification

```bash
kubectl get applications -A
kubectl get pods -A
kubectl get svc -n traefik
kubectl get svc -n argocd
kubectl get svc -n o11y
kubectl get clusterissuers
```

## Notes

- This repo currently points Argo CD at `git@github.com:cmcgalliard/2026-oss-summit.git` and branch `try-three` in several manifests.
- If you fork or rename the repository, update the repo URL and tracked revision in the bootstrap and Argo CD application manifests.
- `build.md` and `.context/` contain additional architecture and service detail used to shape this setup.

## License

See `LICENSE`.

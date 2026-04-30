# PlatformCluster

`PlatformCluster` is a KRO `ResourceGraphDefinition` that provisions a Linode LKE cluster with Crossplane and then creates Argo CD `Application` resources in the management cluster's `argocd` namespace for the requested platform components.

## Prerequisites

- `platform/apps/kro.yaml` synced
- `platform/apps/crossplane.yaml` synced
- `platform/apps/crossplane-providers.yaml` synced
- `platform/crossplane/provider-config.yaml` applied with a `ProviderConfig` named `default`
- Argo CD already running in the management cluster

## Layout

```text
platform/
  apps/      Argo CD Application manifests, including platform-crd
  crd/       Synced KRO ResourceGraphDefinitions
  examples/  Manual-only PlatformCluster examples
  scripts/   Score workload helper scripts
  workloads/ Shared Score source and rendered manifests
```

`platform/bootstrap/app-of-apps.yaml` only reconciles `platform/apps/`, so the live RGD lives under `platform/crd/` and is pulled in through `platform/apps/platform-crd.yaml`.

`platform/crd/platformcluster-kro-rbac.yaml` and `platform/crd/platformcluster-kro-rbac-secrets.yaml` aggregate the extra controller permissions KRO needs in `rbac.mode=aggregation` to watch `PlatformCluster` instances and manage the resources declared by the graph.

## Sync Order

- Wave 3: `kro`
- Wave 5: `platform-crd`

The extra gap leaves KRO time to register its APIs before Argo CD applies `platform/crd/platformcluster-rgd.yaml`.

## Install Flow

1. Bootstrap the management cluster so Argo CD starts reconciling `platform/apps/`.
2. Wait for the `platform-crd` application to sync.
3. Confirm the `PlatformCluster` CRD exists.
4. Apply one of the examples manually.

```bash
kubectl get application platform-crd -n argocd
kubectl get resourcegraphdefinitions.kro.run
kubectl explain platformcluster
kubectl apply -f platform/examples/dev-cluster.yaml
```

## Component Model

The `PlatformCluster` schema exposes these built-in components:

- `o11yStack`
- `harbor`
- `headlamp`

When enabled, the RGD creates Argo CD `Application` resources in the management cluster's `argocd` namespace and points each application's `spec.destination.server` at the new LKE cluster endpoint.

The cluster registration job also creates an Argo CD cluster secret with `stringData.name: <clusterName>`. User workload applications can target that registered child cluster with `spec.destination.name: <clusterName>` instead of hard-coding the API server URL.

When `headlamp.enabled: true`, the graph also publishes a management-cluster secret named `<clusterName>-headlamp-token` in the same namespace as the `PlatformCluster`. The secret contains the Headlamp login token under `data.token`.

Retrieve it with:

```bash
kubectl get secret <clusterName>-headlamp-token -n <platformClusterNamespace> \
  -o go-template='{{index .data "token" | base64decode}}'
```

## Examples

Examples are intentionally not under `platform/crd/`, so Argo CD does not auto-create demo clusters during sync.

- `platform/examples/dev-cluster.yaml`
- `platform/examples/staging-cluster.yaml`
- `platform/examples/prod-cluster.yaml`

Apply them manually when you want to test or provision a cluster.

## User Workloads

Once a child cluster exists and Argo CD has registered it, developers can deploy workloads to it through git.

Use this repo contract:

```text
platform/
  workloads/
    apps/
      <app>/
        score.yaml
        rendered/
          namespace.yaml
          manifests.yaml
```

Rules:

- `spec.components.userApps.enabled` is the allowlist of shared app names for that cluster
- `PlatformCluster` creates one Argo app per enabled name: `<cluster>-<app>`
- each app uses `spec.destination.name: <cluster>`
- each app points at `platform/workloads/apps/<app>/rendered`
- `namespace.yaml` is committed so prune-on-delete stays predictable
- app names are repo-global and reusable across clusters

Helper scripts:

- `platform/scripts/scaffold-score-app.sh <app>`
- `platform/scripts/render-score-app.sh <app>`
- `platform/scripts/check-score-app.sh [<app>]`

Sample app:

- `platform/workloads/apps/demo-app/`

Delete flow:

1. Remove the app name from `spec.components.userApps.enabled`
2. Remove `platform/workloads/apps/<app>/`
3. Commit and push so KRO prunes the Argo app and Argo prunes the workload resources

Set `spec.components.userApps.enabled` to the exact app names that should be deployed to the cluster.

This flow deploys workloads onto an existing child cluster. It does not provision the cluster, ingress, DNS, or TLS for the workload.

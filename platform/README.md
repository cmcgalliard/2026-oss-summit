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
```

`platform/bootstrap/app-of-apps.yaml` only reconciles `platform/apps/`, so the live RGD lives under `platform/crd/` and is pulled in through `platform/apps/platform-crd.yaml`.

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

## Examples

Examples are intentionally not under `platform/crd/`, so Argo CD does not auto-create demo clusters during sync.

- `platform/examples/dev-cluster.yaml`
- `platform/examples/staging-cluster.yaml`
- `platform/examples/prod-cluster.yaml`

Apply them manually when you want to test or provision a cluster.

# Services Reference
**Project**: OSS Summit 2026 Platform Engineering Demo  
**Last Updated**: 2026-04-01

## ArgoCD
- **Role**: GitOps controller — manages all platform services from this repo
- **Helm Repo**: `https://argoproj.github.io/argo-helm`
- **Chart**: `argo/argo-cd`
- **Version**: `9.4.17`
- **Namespace**: `argocd`
- **Values**: `platform/bootstrap/argocd/values.yaml`
- **Install**: Bootstrap via `platform/bootstrap/bootstrap.sh` (imperative, once)
- **Access**: LoadBalancer IP, admin/admin (demo)
- **Sync Wave**: N/A (bootstrap)

## Crossplane
- **Role**: Kubernetes-native infrastructure provisioning (creates LKE clusters)
- **Helm Repo**: `https://charts.crossplane.io/stable`
- **Chart**: `crossplane/crossplane`
- **Version**: `1.18.1`
- **Namespace**: `crossplane-system`
- **Values**: `platform/helm/crossplane/values.yaml`
- **ArgoCD App**: `platform/apps/crossplane.yaml`
- **Sync Wave**: 1

### Crossplane Linode Provider
- **Package**: `xpkg.upbound.io/linode/provider-linode:v0.0.29`
- **Manifests**: `platform/crossplane/`
  - `linode-token-secret.yaml` — Secret template (token injected at bootstrap)
  - `provider-linode.yaml` — Provider CRD (wave 1)
  - `provider-config.yaml` — ProviderConfig pointing to secret (wave 2)
- **ArgoCD App**: `platform/apps/crossplane-providers.yaml`
- **Sync Wave**: 2

## Observability Stack (O11y)
- **Helm Repo**: `https://grafana.github.io/helm-charts`
- **Namespace**: `o11y`
- **ArgoCD App**: `platform/apps/o11y.yaml`
- **Sync Wave**: 3

### Loki (Logs)
- **Chart**: `grafana/loki`
- **Version**: `6.55.0` (Loki 3.6.7)
- **Mode**: SingleBinary (monolithic, suitable for demo)
- **Values**: `platform/helm/o11y/loki-values.yaml`
- **Storage**: `linode-block-storage-retain`, 10Gi
- **Retention**: 31 days

### Tempo (Traces)
- **Chart**: `grafana/tempo`
- **Version**: `1.24.4` (Tempo 2.9.0)
- **Values**: `platform/helm/o11y/tempo-values.yaml`
- **Storage**: `linode-block-storage-retain`, 10Gi
- **Retention**: 7 days

### Grafana (UI)
- **Chart**: `grafana/grafana`
- **Version**: `10.5.15` (Grafana 12.3.1)
- **Values**: `platform/helm/o11y/grafana-values.yaml`
- **Access**: LoadBalancer, admin/grafana-demo (demo)
- **Datasources**: Loki + Tempo pre-configured with trace correlation

## KRO (Kubernetes Resource Orchestrator)
- **Role**: Higher-level platform abstractions via ResourceGraphDefinitions
- **Helm OCI**: `registry.k8s.io/kro/charts/kro`
- **Version**: `0.9.0`
- **Namespace**: `kro-system`
- **Values**: `platform/helm/kro/values.yaml`
- **ArgoCD App**: `platform/apps/kro.yaml`
- **Sync Wave**: 3
- **CRDs**: `resourcegraphdefinitions.kro.run`, `graphrevisions.internal.kro.run`
- **Note**: Uses `Replace=true` syncOption for CRD updates

## Score.dev
- **Role**: Platform-agnostic workload specification (developer abstraction layer)
- **Type**: CLI translation layer — NOT an in-cluster operator
- **CLI Image**: `ghcr.io/score-spec/score-k8s:latest` (v0.10.3)
- **Pattern**: `score.yaml` (spec) → `score-k8s generate` → `manifests.yaml` (K8s)
- **Files**:
  - `platform/score/score.yaml` — Sample Score workload spec
  - `platform/score/manifests.yaml` — Pre-generated K8s manifests (ArgoCD deploys these)
- **ArgoCD App**: `platform/apps/score.yaml` (deploys `platform/score/manifests.yaml`)
- **Sync Wave**: 3

## Sync Wave Order
```
Wave 0: [bootstrap] ArgoCD + linode-credentials Secret
Wave 1: Crossplane core (CRDs install)
Wave 2: Crossplane Linode Provider + ProviderConfig (needs wave 1 CRDs)
Wave 3: KRO, Loki, Tempo, Grafana, Score (independent)
```

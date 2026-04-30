# Services Reference
**Project**: OSS Summit 2026 Platform Engineering Demo  
**Last Updated**: 2026-04-04

## ArgoCD
- **Role**: GitOps controller — manages all platform services from this repo
- **Helm Repo**: `https://argoproj.github.io/argo-helm`
- **Chart**: `argo/argo-cd`
- **Version**: `9.4.17`
- **Namespace**: `argocd`
- **Values**: `platform/bootstrap/argocd/values.yaml`
- **Install**: Bootstrap via `platform/bootstrap/bootstrap.sh` (imperative, once)
- **Access**: LoadBalancer IP, admin / `argocd-initial-admin-secret`
- **Sync Wave**: N/A (bootstrap)

## cert-manager
- **Role**: TLS certificate management via Let's Encrypt ACME
- **Helm OCI**: `oci://quay.io/jetstack/charts`
- **Chart**: `cert-manager`
- **Version**: `v1.20.1`
- **Namespace**: `cert-manager`
- **Values**: `platform/helm/cert-manager/values.yaml`
- **ArgoCD App**: `platform/apps/cert-manager.yaml`
- **Sync Wave**: 1
- **CRDs**: Installed via Helm (`crds.enabled: true`, `crds.keep: true`)

## cert-manager ClusterIssuers
- **Role**: ACME issuers for Let's Encrypt (staging + production)
- **Manifests**: `platform/cert-manager/`
  - `letsencrypt-staging.yaml` — ACME staging (rate-limit safe, use for testing)
  - `letsencrypt-prod.yaml` — ACME production (real certs)
- **ArgoCD App**: `platform/apps/cert-manager-issuers.yaml`
- **Sync Wave**: 4 (after cert-manager + traefik are ready)
- **HTTP01 solver**: via `ingressClassName: traefik`
- **ACME email**: `cmcgalliard@gmail.com`

## Traefik
- **Role**: Ingress controller — routes external traffic to in-cluster services
- **Helm Repo**: `https://traefik.github.io/charts`
- **Chart**: `traefik`
- **Version**: `39.0.7` (Traefik Proxy v3.6.12)
- **Namespace**: `traefik`
- **Values**: `platform/helm/traefik/values.yaml`
- **ArgoCD App**: `platform/apps/traefik.yaml`
- **Sync Wave**: 2
- **Service**: LoadBalancer (LKE auto-provisions NodeBalancer)
- **IngressClass**: `traefik` (default)

## external-dns
- **Role**: Automatic DNS record management for Services and Ingresses
- **Helm Repo**: `https://kubernetes-sigs.github.io/external-dns/`
- **Chart**: `external-dns`
- **Version**: `1.19.0` (App v0.19.0)
- **Namespace**: `external-dns`
- **Values**: `platform/helm/external-dns/values.yaml`
- **ArgoCD App**: `platform/apps/external-dns.yaml`
- **Sync Wave**: 3
- **Provider**: `linode`
- **Domain filter**: `ossdemo.soupcan.io`
- **Credentials**: `linode-token` Secret in `external-dns` namespace (key: `token`)
- **Policy**: `upsert-only` (safe — never deletes DNS records)
- **TXT owner**: `lke-oss-summit`

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

### Tempo (Traces)
- **Chart**: `grafana/tempo`
- **Version**: `1.24.4` (Tempo 2.9.0)
- **Values**: `platform/helm/o11y/tempo-values.yaml`

### Grafana (UI)
- **Chart**: `grafana/grafana`
- **Version**: `10.5.15` (Grafana 12.3.1)
- **Values**: `platform/helm/o11y/grafana-values.yaml`
- **Access**: LoadBalancer, admin / `grafana-admin-secret` (random, set during bootstrap)
- **Datasources**: Loki + Tempo pre-configured with trace correlation

## KRO (Kubernetes Resource Orchestrator)
- **Role**: Higher-level platform abstractions via ResourceGraphDefinitions
- **Helm OCI**: `registry.k8s.io/kro/charts/kro`
- **Version**: `0.9.0`
- **Namespace**: `kro-system`
- **Values**: `platform/helm/kro/values.yaml`
- **ArgoCD App**: `platform/apps/kro.yaml`
- **Sync Wave**: 3

## Score.dev
- **Role**: Platform-agnostic workload specification (developer abstraction layer)
- **Type**: CLI translation layer — NOT an in-cluster operator
- **Files**: `platform/workloads/<cluster>/<app>/`
- **ArgoCD App**: KRO creates `<cluster>-<app>` for names listed in `spec.components.userApps.enabled`
- **Sync Wave**: 3

## Sync Wave Order
```
Wave 0: [bootstrap] ArgoCD + linode-credentials + linode-token + grafana-admin-secret
Wave 1: cert-manager (CRDs + controller), crossplane (CRDs)
Wave 2: traefik (ingress), crossplane-providers (linode provider + config)
Wave 3: kro, loki, tempo, grafana, external-dns, workload apps
Wave 4: cert-manager-issuers (letsencrypt-staging, letsencrypt-prod)
```

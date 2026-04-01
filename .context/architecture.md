# Platform Engineering Context
**Project**: OSS Summit 2026 — Kubernetes Platform Engineering Demo  
**Last Updated**: 2026-04-01

## Cluster Info
- **Provider**: Akamai Cloud (Linode Kubernetes Engine)
- **Cluster ID**: lke586365
- **Region**: us-southeast-2
- **API Endpoint**: https://8f67b4fc-3085-4d29-adea-106d5ee96e96.us-southeast-2-gw.linodelke.net:443
- **Kubeconfig**: `kubeconfig.yaml` (gitignored)

## Architecture Decisions

### GitOps Model
- ArgoCD is the GitOps controller tracking this repo
- All platform services are declarative ArgoCD Applications
- Repo is source of truth; cluster state reconciles to git state
- Branch: current branch tracked by ArgoCD

### Installation Bootstrap Order
1. `helm install argocd` using `platform/bootstrap/argocd/values.yaml`
2. ArgoCD then manages all subsequent Applications from `platform/apps/`

### Sync Waves (ArgoCD ordering)
```
argocd.argoproj.io/sync-wave: "1"  # crossplane core
argocd.argoproj.io/sync-wave: "2"  # crossplane providers (need CRDs from wave 1)
argocd.argoproj.io/sync-wave: "3"  # kro, o11y, score (independent)
```

### Namespaces
| Service | Namespace |
|---------|-----------|
| ArgoCD | argocd |
| Crossplane | crossplane-system |
| Crossplane Providers | crossplane-system |
| Observability | monitoring |
| KRO | kro-system |
| Score | score-system |

## Secrets Management
- `OSS_LINODE_API_TOKEN` environment variable → Kubernetes Secret `linode-credentials` in `crossplane-system`
- Secret creation is outside GitOps (imperative, before ArgoCD sync)

## Services

### ArgoCD
- Helm repo: https://argoproj.github.io/argo-helm
- Chart: argo/argo-cd
- Namespace: argocd
- Bootstrap method: `helm install argocd argo/argo-cd -n argocd -f platform/bootstrap/argocd/values.yaml`

### Crossplane
- Helm repo: https://charts.crossplane.io/stable
- Chart: crossplane/crossplane
- Namespace: crossplane-system
- Linode provider: `xpkg.upbound.io/linode/provider-linode`

### Observability (O11y)
- Helm repo: https://grafana.github.io/helm-charts
- Components: grafana/grafana + grafana/loki + grafana/tempo
- Namespace: monitoring

### KRO
- Helm: OCI registry (ghcr.io/kro-run/kro)
- Namespace: kro-system

### Score.dev
- Spec: https://score.dev / https://github.com/score-spec
- Integration: TBD (CLI-based or operator-based)

## Next Steps (user-guided)
1. User will guide on additional steps after base platform bootstrap
2. Likely: composite resources with Crossplane for LKE provisioning
3. Likely: KRO ResourceGraphs for higher-level platform abstractions
4. Likely: Score workload specs for application deployment

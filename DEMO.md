# OSS Summit Demo Runbook

## Demo Goal

Show that this repo turns simple user intent into real infrastructure and applications through a GitOps-driven platform flow.

- a simple `PlatformCluster` manifest provisions and configures an LKE cluster on the Akamai Cloud
- platform services are attached declaratively based on feature flags
- application teams ship a single Score spec instead of hand-authoring Kubernetes YAML
- DNS and traffic routing are derived automatically from Kubernetes resources

## Story Arc

1. Start from the platform API: `PlatformCluster`
2. Show how KRO and Crossplane turn that API into a real Linode LKE cluster
3. Show how Argo CD picks up the new cluster and deploys platform components
4. Show how a Score workload becomes a working app with database, service, gateway, and route
5. End on the developer and operator outcome: lower cognitive load, safer changes, easier automation

## Why This Is Interesting

- `kro` positions itself as a way to build declarative, secure, and verifiable Kubernetes abstractions with a simple schema and CEL-based expressions.
- `Crossplane` describes itself as a control plane framework for platform engineering.
- `Gateway API` is the official next-generation Kubernetes API for L4/L7 routing, designed to be expressive and role-oriented.
- `Score` is a developer-centric, platform-agnostic workload spec intended to keep workload configuration consistent across environments.
- `external-dns` watches Kubernetes resources and synchronizes them with DNS providers instead of making teams manage records manually.

This repo combines those ideas into one platform flow.

## What This Repo Actually Implements

- Base cluster bootstrapped with Argo CD using app-of-apps
- Platform services managed from git under `platform/apps/` and `platform/helm/`
- A KRO `ResourceGraphDefinition` published as `PlatformCluster`
- Crossplane-managed Linode LKE clusters
- Automatic Argo CD cluster registration for child clusters
- Optional child-cluster services based on `spec.components.*`
- Score-rendered app workloads under `platform/workloads/apps/*/rendered`
- Gateway API routing via Traefik
- DNS publishing for `HTTPRoute` hostnames under `oss.baby` via `external-dns`

## Demo Flow

### 1. Show the platform API

Open:

```bash
vim platform/examples/demo-cluster.yaml
vim platform/crd/platformcluster-rgd.yaml
```

Call out:

- `platform/examples/demo-cluster.yaml` is the user-facing API.
- The user only sets cluster intent: name, region, Kubernetes version, node pool, and enabled components.
- `platform/crd/platformcluster-rgd.yaml` is where the platform team encodes the implementation.
- The schema is small and readable even though the graph creates many resources.
- The graph exposes useful status back to the custom resource, including `clusterStatus` and `clusterEndpoint`.

Talking points:

- This is the platform contract. Teams consume this API, not raw cloud and Argo plumbing.
- KRO handles dependency ordering and lets the graph reference status from previously created resources.
- In this repo that means the cluster endpoint produced by Crossplane is later reused to target Argo CD applications.
- The abstraction is still Kubernetes-native, so everything is inspectable with normal cluster tooling.

### 2. Show the application contract

Open:

```bash
vim platform/workloads/apps/demo-app/score.yaml
ls -l platform/workloads/apps/demo-app/rendered/
vim platform/workloads/apps/demo-app/rendered/manifests.yaml
vim platform/workloads/apps/demo-app/rendered/gateway.yaml
```

Call out:

- The Score file is short and workload-centric.
- The app declares what it needs: HTTP service, Postgres, and a route.
- The rendered manifests show the underlying Kubernetes detail the developer did not have to hand-write.
- In this sample app, Score renders a `Deployment`, `Service`, `StatefulSet`, `Secret`, `HTTPRoute`, and supporting resources.
- The route hostname is `demo.oss.baby`.

Talking points:

- Score keeps the developer interface stable while the platform implementation can evolve.
- This is the "configure once" story: the workload describes intent, not cluster-specific plumbing.
- The rendered YAML is committed, so GitOps still has explicit, reviewable manifests.
- The combination is useful for AI agents too because the interface is compact, but the output is concrete.

### 3. Create a cluster through git

Run:

```bash
cp platform/examples/demo-cluster.yaml platform/clusters/demo-cluster.yaml
git add platform/clusters/demo-cluster.yaml
git commit -m "Add demo PlatformCluster"
git push origin main
```

Then refresh or sync the Argo CD `platform-clusters` app.

Call out:

- `platform/apps/platform-clusters.yaml` watches `platform/clusters/`.
- Committing a file into that directory is the act that creates or updates a real cluster.
- Argo CD reconciles the `PlatformCluster`, then KRO and Crossplane take over.

Talking points:

- This is self-service through pull request and git history, not self-service through an opaque portal.
- The app-of-apps pattern is intentionally used here as a platform-admin control point.
- The repo is the source of truth for both infrastructure and workloads.

### 4. Show reconciliation in Kubernetes

Run:

```bash
kubectl get platformcluster
kubectl get linode
kubectl get cluster.lke.linode.upbound.io
```

Call out:

- The `PlatformCluster` resource represents the user request.
- The Crossplane `Cluster` resource is the cloud-facing managed resource.
- Once ready, the graph uses the generated kubeconfig to register the child cluster into Argo CD.

Talking points:

- Crossplane is the infrastructure control plane.
- KRO is the orchestration and abstraction layer above it.
- The value is not just provisioning a cluster. The graph also handles follow-on operational setup.

### 5. Show the cluster in Linode

Show the new LKE cluster in the Linode console.

Call out:

- The infrastructure is real and directly visible in the cloud provider.
- The cluster shape matches the platform API: region, version, node count, and node type.

Talking points:

- This proves the abstraction is not hiding the cloud. It is standardizing access to it.
- The platform can still enforce defaults and guardrails while producing normal cloud resources.

### 6. Show the generated Argo applications

In Argo CD, show the demo cluster's child applications.

Focus on:

- the cluster registration outcome
- the platform app for gateway fabric
- the child-cluster `external-dns` app
- the workload app for `demo-app`

Call out:

- The graph creates one workload application per enabled app name.
- When `gatewayFabric.enabled: true`, the graph also installs Traefik with Gateway API enabled.
- The graph also installs child-cluster `external-dns`, scoped to `oss.baby`, sourcing records from `gateway-httproute`.

Talking points:

- Enabling a feature flag in `PlatformCluster` causes a whole operational slice to appear.
- This is where the abstraction pays off: one field controls several coordinated resources.
- The platform team keeps implementation freedom behind a stable user contract.

### 7. Show the application resources in the child cluster

Show the app resources for the demo cluster:

- `Deployment`
- `Service`
- `HTTPRoute`
- `Gateway`
- Postgres `StatefulSet`
- PVC / volume

If needed, point at these repo paths while explaining:

- `platform/workloads/apps/demo-app/rendered/manifests.yaml`
- `platform/workloads/apps/demo-app/rendered/gateway.yaml`

Talking points:

- The app team asked for an app, a database, and a route.
- The platform delivered a working workload on a newly provisioned cluster.
- Gateway API is the north-south routing model here, rather than old ingress-specific conventions.

### 8. Show the live endpoint

Open the app URL:

```text
http://demo.oss.baby/
```

Also mention the intended route in the sample workload:

```text
demo.oss.baby
```

Call out:

- The repo contains the desired hostname in the workload spec.
- `external-dns` converts route intent into DNS records in Linode DNS.
- The live URL proves the end-to-end chain: git -> Argo CD -> KRO -> Crossplane -> child cluster -> Gateway API -> DNS.

## High-Value Talking Points

### Platform abstraction without hiding Kubernetes

- Consumers get a small API surface.
- Operators still get native Kubernetes resources, status, and drift reconciliation.
- This is abstraction with transparency, not abstraction by black box.

### One repo for platform and workload intent

- The same repo drives bootstrap, platform services, cluster creation, and app deployment.
- That makes reviews, audits, and rollback strategy much simpler. When we say monorepos are back in trend, it's not that it should always be in one repo, but that there is value in co-locating related code and configuration for platform and workloads instead of scattering it across multiple repos, portals, and CLIs.

### Better human and AI ergonomics

- `PlatformCluster` and Score are both compact interfaces.
- They reduce the amount of boilerplate a human or agent has to reason about.
- The generated outputs are still concrete enough to inspect and troubleshoot.

### Swappable implementation behind a stable contract

- The user experience is the custom resource plus the Score file.
- The platform team can change internals later without forcing every app team to relearn the system.
- That is the real value of platform engineering: stable interfaces, evolving implementation.

### Modern Kubernetes networking story

- Gateway API is more expressive and role-oriented than legacy ingress patterns.
- The app only needs an `HTTPRoute` and an enabled gateway fabric.
- DNS automation is attached to the routing resources, so there is less side-channel configuration.

## Optional Variation

If you want to show that the pattern is reusable, also open:

```bash
vim platform/clusters/demo-cluster-switcharoo.yaml
vim platform/workloads/apps/demo-app-switcharoo/score.yaml
```

Use that to emphasize:

- same platform pattern
- different cluster instance
- different enabled app
- optional `headlamp.enabled: true`

## Closing Message

The point of the demo is not only that a cluster appears.

The point is that a platform team can publish a small, legible API for infrastructure and workloads, keep everything in GitOps, and still compose real cloud infrastructure, real Kubernetes networking, and real application deployment end to end.

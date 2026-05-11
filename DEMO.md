

```
vim platform/examples/demo-cluster.yaml
vim platform/crd/platformcluster-rgd.yaml
```

```
vim platform/workloads/apps/demo-app/score.yaml
ls -l platform/workloads/apps/demo-app/rendered/
```

```
cp platform/examples/demo-cluster.yaml platform/clusters/
git add platform/clusters/demo-cluster.yaml
git commit -m "Add demo PlatformCluster"
git push origin main
```

Refresh the platform-clusters app

```
k get platformcluster
k get linode
k get cluster.lke.linode.upbound.io
```

Show the LKE Cluster in the Linode console

Show the argo apps for the demo cluster 
- Show the app itself, deployment, httproute, database, volume, etc
- Show the gateway, externaldns

http://dnskumwsd.oss.baby/

1. Managed to expose very rich Kubernetes features via a simple user-experience.
2. Makes it easy for humans and AI agents to reason about. 
3. Lowers the cognitive load of maintaining and reviewing cluster and applications.
4. We have something that is composable and where the underlying implementation can be swapped out without changing the user experience.

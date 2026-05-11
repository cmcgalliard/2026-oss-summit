# Base Cluster Build

There is a Kubernetes cluster that has been provisioned and the kubeconfig file is available at `./kubeconfig.yaml`. This cluster will be used as the base cluster for building other Kubernetes clusters and platforms for team development and testing.



## Current State and things to correct:
- The base cluster is setup and Argo CD is installed and some applications are installed, but not functional.
- there is a `./platform` folder that has argo apps, the boot strap and some helm values files. although this is close to what i want it is not exact
- i want the argo apps to track this repo and branch targeting the values files in the `./platform/helm` folder. this will allow us to have a single source of truth for the cluster configuration and make it easier to manage and update the clusters as needed.
- i would also like to install external-dns and cert-manager in the base cluster to manage DNS records and TLS certificates for the applications deployed in the cluster. this will help ensure that the applications are accessible and secure. as well as a simple ingress controller based on Traefik to route traffic to the applications deployed in the cluster. use type loadbalancer on the service to expose the ingress controller to the internet. this is an LKE cluster so this will work out of the box.
- make sure that the argo password is set to a random string i can caputer by looking at a secret in the argocd namespace. this will allow me to access the Argo CD dashboard and manage the applications deployed in the cluster.
- make sure that all passwords are random strings at all times


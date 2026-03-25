# Ideas

* Talk about the simple unified interface to apps and infra that gets translated into CRs. Easier to approach for Cloud Native novices

# Submission

## From Apps to Infrastructure: A Cloud-Native First Approach

## Speaker Information
- Name: Corey McGalliard
- Name: Julien Semaan

### Description
Traditional infrastructure GitOps workflows, commonly built on tools like Terraform or OpenTofu, often struggle with state management, limited reconciliation, and delayed drift detection. Because these systems operate outside the Kubernetes control plane, infrastructure changes follow different lifecycle and failure semantics than applications, making it difficult to reason about system-wide correctness and safety.

We'll present a unified approach for managing both applications and infrastructure through the Kubernetes control plane. This approach brings together GitOps controllers and Crossplane to extend the Kubernetes API to infrastructure via an ecosystem of community-supported providers spanning major clouds, alternative clouds, and on-prem. The result is a vendor-neutral foundation where applications and infrastructure follow the same review, lifecycle, and reconciliation model.

### Which track are you submitting for?
Cloud & Orchestration

### Cloud & Orchestration Topic
Cloud Infrastructure and Architecture

### Session Format
Session Presentation (30-40 minutes in length)

### Audience Level
Any

### Benefits to the Ecosystem
This proposal highlights how the open-source ecosystem can converge on a shared, Kubernetes-native model for managing both applications and infrastructure. By using the reconciliation semantics built into Kubernetes, teams can apply the same open, declarative, and continuously converging workflows across the entire stack, reducing fragmentation between how applications and infrastructure are operated.

The approach builds on composable open-source projects working together. GitOps controllers such as Argo CD handle continuous delivery from Git, while Crossplane extends the Kubernetes API to infrastructure and managed services through a broad set of community-supported providers spanning major cloud vendors, alternative clouds, and on-prem platforms. Together, these projects form a vendor-neutral foundation that encourages reuse, interoperability, and collaboration in the open.

By modeling infrastructure as reusable APIs rather than provider-specific automation, this approach enables Infrastructure, Platform and Application teams to collaborate on higher-level abstractions that evolve in public communities. The patterns and lessons shared in this talk are intended to allow teams to build their next generation of Infrastructure management tooling, helping the broader ecosystem move toward more consistent, maintainable, and openly governed Infrastructure GitOps practices.
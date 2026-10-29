# GroupOS — Infrastructure Repository

> Scope: cluster creation and low-level infrastructure definitions.  
> Current environment: local Kind on Podman.

## Directory layout

```text
kubernetes/
  kind/
    local.yaml               # Kind cluster definition
```

Optional local-only operational artifacts may exist (for example `backups/` and `groupos-kind-debug.log`). They **must not** be committed if they contain local state, credentials, or sensitive operational details.

## Local cluster

- Name: `groupos-local`
- kubectl context: `kind-groupos-local`
- Nodes: one control plane and one worker
- Runtime: Podman on macOS Intel
- Recorded Kubernetes node version: `v1.34.0`

Source of truth: `kubernetes/kind/local.yaml`.

## Preflight commands

```bash
podman machine list
podman info
kind version
kubectl version --client
kubectl config get-contexts
```

## Inspect existing cluster

```bash
kind get clusters
kubectl --context kind-groupos-local get nodes -o wide
kubectl --context kind-groupos-local get pods -A
```

## Cluster bootstrap (only on a clean machine)

The original cluster was created with the experimental Podman Kind provider. This command **creates** a cluster and must not be rerun blindly against the existing cluster:

```bash
KIND_EXPERIMENTAL_PROVIDER=podman kind create cluster   --name groupos-local   --config kubernetes/kind/local.yaml   --wait 5m
```

Before any rebuild, record workloads, backup any required stateful data, check Podman resources, and verify you are not disrupting CompanyOS PostgreSQL. Never run broad `podman volume prune` or `podman system reset` as part of routine GroupOS maintenance.

## Local artifact `.gitignore`

Recommended entries:

```gitignore
/backups/
/*.log
*.key
*.pem
.env
.env.*
```

Check `git ls-files backups/ groupos-kind-debug.log` to see whether local artifacts were already tracked. `.gitignore` only prevents new tracking; removing sensitive data from Git history requires separate remediation.

## Ownership boundaries

- This repo owns Kind and low-level infrastructure definition.
- The `gitops` repo owns the desired Kubernetes platform resources and Argo CD applications.
- The `documentation` repo owns guides and runbooks.

Do not store CompanyOS/BARAKA data or configuration in GroupOS infrastructure without authorization and deliberate isolation.

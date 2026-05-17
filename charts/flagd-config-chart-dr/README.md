# flagd-operator

A Helm chart for deploying the [OpenFeature](https://openfeature.dev) **flagd Operator** — a Kubernetes controller that manages flagd deployments and sidecar injection for feature-flag evaluation.

## Overview

The flagd Operator watches OpenFeature custom resources (`FeatureFlag`, `FeatureFlagSource`, `Flagd`) and reconciles the desired state by deploying flagd instances and injecting sidecars into annotated workloads.

## Prerequisites

| Requirement | Version |
|---|---|
| Kubernetes | >= 1.24 |
| Helm | >= 3.10 |
| kubectl | CLI access to the cluster |

## Chart Structure

```
flagd-operator/
├── Chart.yaml                        # Chart metadata
├── values.yaml                       # Default configuration
├── crds/
│   └── crd.yaml                      # FlagdConfig CRD
├── templates/
│   ├── _helpers.tpl                  # Template helpers
│   ├── deployment.yaml               # Operator manager Deployment
│   ├── serviceaccount.yaml           # ServiceAccount for the operator
│   ├── rbac.yaml                     # ClusterRole / ClusterRoleBinding / Role / RoleBinding
│   └── NOTES.txt                     # Post-install usage instructions
└── README.md
```

## Installation

```bash
# Add the chart (local path)
helm install flagd-operator ./flagd-operator \
  --namespace openfeature \
  --create-namespace

# With custom values
helm install flagd-operator ./flagd-operator \
  --namespace openfeature \
  --create-namespace \
  --set replicaCount=2 \
  --set image.tag=v0.12.4
```

## Configuration

| Parameter | Description | Default |
|---|---|---|
| `replicaCount` | Number of operator replicas | `1` |
| `image.repository` | Operator container image | `ghcr.io/open-feature/open-feature-operator` |
| `image.tag` | Image tag (defaults to `appVersion`) | `""` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `serviceAccount.create` | Create a dedicated ServiceAccount | `true` |
| `serviceAccount.name` | Override ServiceAccount name | `""` |
| `leaderElection.enabled` | Enable leader election (HA) | `true` |
| `logLevel` | Log verbosity (`debug`, `info`, `warn`, `error`) | `info` |
| `metricsPort` | Port for Prometheus metrics | `8080` |
| `healthProbePort` | Port for liveness/readiness probes | `8081` |
| `crds.enabled` | Install CRDs with the chart | `true` |
| `resources.limits.cpu` | CPU limit for the manager container | `500m` |
| `resources.limits.memory` | Memory limit for the manager container | `128Mi` |

## RBAC

The chart creates:

- **ClusterRole** `flagd-operator-manager-role` — full CRUD on OpenFeature CRDs, Deployments, Services, ConfigMaps, and Ingresses.
- **ClusterRoleBinding** — binds the above role to the operator ServiceAccount.
- **Role** `flagd-operator-leader-election-role` — namespace-scoped leader-election permissions.
- **RoleBinding** — binds the leader-election role in the release namespace.

## Quick Start

After installation, create a `FeatureFlag` resource and annotate your application:

```yaml
apiVersion: core.openfeature.dev/v1beta1
kind: FeatureFlag
metadata:
  name: my-flags
spec:
  flagSpec:
    flags:
      enable-dark-mode:
        state: ENABLED
        variants:
          "on": true
          "off": false
        defaultVariant: "off"
```

Annotate your pod template:

```yaml
metadata:
  annotations:
    openfeature.dev/enabled: "true"
    openfeature.dev/featureflagsource: "<namespace>/my-flag-source"
```

## Upgrading

```bash
helm upgrade flagd-operator ./flagd-operator -n openfeature
```

## Uninstalling

```bash
helm uninstall flagd-operator -n openfeature
```

> **Note:** CRDs installed by this chart are **not** deleted on uninstall. Remove them manually if needed:  
> `kubectl delete crd flagdconfigs.flagd.dev`

## Maintainer

| Name | Email |
|---|---|
| snatakSneha | sneha.joshi.snaatak@mygurukulam.co |

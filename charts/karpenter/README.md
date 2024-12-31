## Karpenter

Karpenter is an open-source Kubernetes cluster autoscaler built for efficiency and speed. This Helm chart installs Karpenter in your Kubernetes cluster and can be used to manage your node pools for dynamically scaling your infrastructure. This chart supports automated deployment of Karpenter, including the creation of NodePools, EC2NodeClasses, IAM roles, and other necessary resources.

To install Karpenter, use the following commands:

```shell
$ helm repo add ot-helm https://ot-container-kit.github.io/helm-charts/
$ helm install <my-release> ot-helm/karpenter --namespace <namespace>
```

To upgrade the setup:

```shell
$ helm upgrade <my-release> ot-helm/karpenter --install --namespace <namespace>
```

To uninstall the chart:

```shell
$ helm delete <my-release> --namespace <namespace>
```

### Pre-Requisites

- Kubernetes => 1.18+
- Helm => 3.X
- Karpenter Operator => 0.1.0
- IAM Roles for Karpenter

### Parameters

| **Name**                                  | **Value**                | **Description**                                      |
|-------------------------------------------|:------------------------:|------------------------------------------------------|
| `image.name`                              | quay.io/karpenter        | Name of the Karpenter controller image               |
| `image.tag`                               | v0.7.0                  | Tag for the Karpenter controller image               |
| `image.imagePullPolicy`                   | IfNotPresent            | Image Pull Policy of the Karpenter controller        |
| `image.pullSecret`                        | ""                       | Image Pull Secret for private registry              |
| `nodePools`                               | []                       | List of NodePools to be created                     |
| `nodePools.name`                          | default-nodepool         | Name of the NodePool                                |
| `nodePools.labels`                        | {}                       | Labels for the NodePool                             |
| `nodePools.annotations`                   | {}                       | Annotations for the NodePool                        |
| `nodePools.requirements`                  | []                       | Node requirements like CPU, memory, etc.            |
| `nodePools.taints`                        | []                       | Taints for the NodePool                             |
| `nodePools.expireAfter`                   | 720h                     | Expiration duration for idle NodePools              |
| `nodePools.limits.cpu`                    | "1000m"                  | CPU limit for the NodePool                          |
| `nodePools.limits.memory`                 | "2Gi"                    | Memory limit for the NodePool                       |
| `nodePools.disruption.consolidationPolicy`| WhenEmptyOrUnderutilized | Consolidation policy for underutilized nodes        |
| `nodePools.disruption.consolidateAfter`   | 1m                       | Time before consolidating underutilized nodes       |
| `serviceMonitor.enabled`                  | false                    | Enable or disable the ServiceMonitor for Prometheus |
| `serviceMonitor.interval`                 | 30s                      | Interval for metrics scraping                       |
| `serviceMonitor.scrapeTimeout`            | 10s                      | Timeout for scraping metrics                        |
| `serviceMonitor.namespace`                | monitoring               | Namespace where Prometheus operator is running      |
| `resources`                               | {}                       | Request and limits for Karpenter components         |
| `nodeSelector`                            | {}                       | Node selector for Karpenter                          |
| `priorityClassName`                       | ""                       | Priority class name for Karpenter                   |
| `affinity`                                | {}                       | Affinity rules for Karpenter components             |
| `tolerations`                             | []                       | Tolerations for Karpenter components                |
| `securityContext`                         | {}                       | Security context for Karpenter components           |

### Example `values.yaml`

```yaml
nodePools:
  - name: default-nodepool
    labels:
      environment: production
    annotations:
      dedicated: true
    requirements:
      - key: "kubernetes.io/arch"
        operator: "In"
        values:
          - amd64
    taints:
      - key: "dedicated"
        value: "true"
        effect: "NoSchedule"
    nodeClass:
      group: karpenter.k8s.aws
      kind: EC2NodeClass
      name: default
    expireAfter: 720h
    limits:
      cpu: "1000m"
      memory: "2Gi"
    disruption:
      consolidationPolicy: "WhenEmptyOrUnderutilized"
      consolidateAfter: "1m"
```

This `values.yaml` example deploys a Karpenter setup with a NodePool named `default-nodepool`, containing specifications such as labels, annotations, requirements, taints, node class, and limits.


### Notes:

- Karpenter automatically creates and manages NodePools as part of the installation process.
- Make sure to configure the IAM roles required by Karpenter for it to interact with EC2 instances and manage resources along with all prerequisites .
- The chart will ensure the Karpenter controller and NodePools are deployed correctly with all required configurations.
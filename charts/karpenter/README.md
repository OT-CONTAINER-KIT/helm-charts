
# Karpenter

Karpenter is an open-source Kubernetes cluster autoscaler built for efficiency and speed. This Helm chart installs Karpenter in your Kubernetes cluster and can be used to manage your node pools for dynamically scaling your infrastructure. This chart supports automated deployment of Karpenter, including the creation of NodePools, EC2NodeClasses, IAM roles, and other necessary resources.

To install Karpenter, use the following commands:

```shell
$ helm repo add ot-helm https://ot-container-kit.github.io/helm-charts/
$ helm install karpenter ot-helm/karpenter --namespace kube-system
```

To upgrade the setup:

```shell
$ helm upgrade karpenter ot-helm/karpenter --install --namespace kube-system
```

To uninstall the chart:

```shell
$ helm delete karpenter --namespace kube-system
```

### Pre-Requisites

- Kubernetes => 1.18+
- Helm => 3.X
- Karpenter Operator => 0.1.0
- Open ID Connector (EKS) => https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html
- IAM Roles for Karpenter
- Add tags to subnets and security groups
- Update aws-auth ConfigMap

### Parameters

|                             **Name**                               |              **Value**         |                   **Description**              |
|--------------------------------------------------------------------|:-------------------------------|------------------------------------------------|
| `karpenter.settings.clusterName`                                   | `my-cluster`                   | The name of your Kubernetes cluster            |     
| `karpenter.serviceAccount.annotations.eks.amazonaws.com/role-arn`  |  Required                      | IAM role ARN for Karpenter controller          |
| `karpenter.controller.resources.requests.cpu`                      | `1`                            | CPU request for Karpenter controller           |
| `karpenter.controller.resources.requests.memory`                   | `1Gi`                          | Memory request for Karpenter controller        |
| `karpenter.controller.resources.limits.cpu`                        | `1`                            | CPU limit for Karpenter controller             |
| `karpenter.controller.resources.limits.memory`                     | `1Gi`                          | Memory limit for Karpenter controller          |
| `nodePools`                                                        | []                             | List of NodePools to be created                |
| `nodePools.name`                                                   | default-nodepool               | Name of the NodePool                           |
| `nodePools.labels`       - If not required can be omiited          | {}                             | Labels for the NodePool                        |
| `nodePools.annotations`  - If not required can be omiited          | {}                             | Annotations for the NodePool                   |
| `nodePools.requirements` - Can be empty []                         | []                             | Node requirements like CPU, memory, etc.       |
| `nodePools.taints`       - If not required can be omiited          | []                             | Taints for the NodePool                        |
| `nodePools.expireAfter`                                            | 720h                           | Expiration duration for idle NodePools         |
| `nodePools.limits.cpu`   - Required Field                          | "1000m"                        | CPU limit for the NodePool                     |
| `nodePools.limits.memory`- If not required can be omiited          | "2Gi"                          | Memory limit for the NodePool                  |
| `nodePools.disruption.consolidationPolicy` - Required Field        | WhenEmptyOrUnderutilized       | Consolidation policy for underutilized nodes   |
| `nodePools.disruption.consolidateAfter`    - Required Field        | 1m                             | Time before consolidating underutilized nodes  |

### Example1 `values.yaml`

Below is an example for creation of a nodepool which can be modified inside values.yaml .

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

### Example2 `values.yaml`

```yaml

nodePools:
  - name: default
    requirements:
      - key: kubernetes.io/arch
        operator: In
        values:
          - "amd64"
      - key: kubernetes.io/os
        operator: In
        values:
          - "linux"
      - key: karpenter.sh/capacity-type
        operator: In
        values:
          - "on-demand"
      - key: karpenter.k8s.aws/instance-category
        operator: In
        values:
          - "t"
          - "m"
          - "r"
      - key: karpenter.k8s.aws/instance-generation
        operator: Gt
        values:
          - "2"
    nodeClass:
      group: karpenter.k8s.aws
      kind: EC2NodeClass
      name: default
    expireAfter: 720h
    limits:
      cpu: "1000"
    disruption:
      consolidationPolicy: WhenEmptyOrUnderutilized
      consolidateAfter: 1m
    annotations:
      example.com/owner: "my-team"
      example.com/maintainer: "admin@company.com"
   # taints:
   #   - key: "example.com/special-taint"
   #     value: "special-value"
   #     effect: "NoExecute"
    labels:
      environment: production
      team: "engineering"
```


### Notes:

- Karpenter automatically creates and manages NodePools as part of the installation process.
- Make sure to configure the IAM roles required by Karpenter for it to interact with EC2 instances and manage resources along with all prerequisites.
- The chart will ensure the Karpenter controller and NodePools are deployed correctly with all required configurations.
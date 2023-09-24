# Redis Cluster

Redis is a key-value based distributed database, this helm chart is for redis cluster setup. This helm chart needs [Redis Operator](../redis-operator) inside Kubernetes cluster. The redis cluster definition can be modified or changed by [values.yaml](./values.yaml).

```shell
helm repo add ot-helm https://ot-container-kit.github.io/helm-charts/

helm install <my-release> ot-helm/redis-cluster \
    --set redisCluster.clusterSize=3 --namespace <namespace> --create-namespace
```

Redis setup can be upgraded by using `helm upgrade` command:-

```shell
helm upgrade <my-release> ot-helm/redis-cluster --install \
    --set redisCluster.clusterSize=5 --namespace <namespace>
```

For uninstalling the chart:-

```shell
helm delete <my-release> --namespace <namespace>
```

## Pre-Requisities

- Kubernetes 1.15+
- Helm 3.X
- Redis Operator 0.7.0

## Parameters

The following table lists the configurable parameters of the chart and their default values.

| Parameter                                              | Description                                 | Default                  |
|--------------------------------------------------------|---------------------------------------------|--------------------------|
| `redisCluster.clusterSize`                             | Cluster size                                | `3`                      |
| `redisCluster.clusterVersion`                          | Redis cluster version                       | `v7`                     |
| `redisCluster.persistenceEnabled`                      | Persistence switch                          | `true`                   |
| `redisCluster.image`                                   | Redis image                                 | `quay.io/opstree/redis`  |
| `redisCluster.tag`                                     | Image tag                                   | `v7.0.12`                |
| `redisCluster.imagePullPolicy`                         | Image pull policy                           | `Always`                 |
| `redisCluster.redisSecret.secretName`                  | Redis secret name                           | `""`                     |
| `redisCluster.redisSecret.secretKey`                   | Redis secret key                            | `""`                     |
| `redisCluster.resources`                               | Resource limits and requests for Redis      | `{}`                     |
| `redisCluster.leader.replicas`                         | Number of leader replicas                   | `3`                      |
| `redisCluster.leader.serviceType`                      | Leader service type                         | `ClusterIP`              |
| `redisCluster.leader.affinity`                         | Leader pod affinity                         | `{}`                     |
| `redisCluster.leader.tolerations`                      | Leader pod tolerations                      | `[]`                     |
| `redisCluster.leader.nodeSelector`                     | Node selector for leader                    | `{}`                     |
| `redisCluster.leader.securityContext`                  | Leader pod security context                 | `{}`                     |
| `redisCluster.leader.terminationGracePeriodSeconds`    | Grace period for leader termination         | `0`                      |
| `redisCluster.follower.replicas`                       | Number of follower replicas                 | `3`                      |
| `redisCluster.follower.serviceType`                    | Follower service type                       | `ClusterIP`              |
| `redisCluster.follower.affinity`                       | Follower pod affinity                       | `{}`                     |
| `redisCluster.follower.tolerations`                    | Follower pod tolerations                    | `[]`                     |
| `redisCluster.follower.nodeSelector`                   | Node selector for follower                  | `{}`                     |
| `redisCluster.follower.securityContext`                | Follower pod security context               | `{}`                     |
| `redisCluster.follower.terminationGracePeriodSeconds`  | Grace period for follower termination       | `0`                      |
| `labels`                                               | Custom labels                               | `{}`                     |
| `annotations`                                          | Custom annotations                          | `{}`                     |
| `pdb.enabled`                                          | PDB enablement                              | `false`                  |
| `pdb.maxUnavailable`                                  | Maximum unavailable PDBs                    | `1`                      |
| `pdb.minAvailable`                                    | Minimum available PDBs                      | `1`                      |
| `externalConfig.enabled`                              | External configuration enablement           | `false`                  |
| `externalConfig.data`                                 | External configuration data                 | (provided data)          |
| `readinessProbe`...                                    | Readiness probe configurations              | (provided configurations)|
| `livenessProbe`...                                     | Liveness probe configurations               | (provided configurations)|
| `externalService`...                                   | External service configurations             | (provided configurations)|
| `serviceMonitor`...                                    | Service monitor configurations              | (provided configurations)|
| `redisExporter`...                                     | Redis exporter configurations               | (provided configurations)|
| `sidecars`                                            | Additional sidecar configurations           | `[]`                     |
| `storageSpec`...                                       | Storage specifications                      | (provided configurations)|
| `podSecurityContext.runAsUser`                        | User ID for the pod                         | `1000`                   |
| `podSecurityContext.fsGroup`                          | File system group ID for the pod            | `1000`                   |
| `priorityClassName`                                   | Name of the priority class                  | `""`                     |
| `serviceAccountName`                                  | Name of the service account                 | `""` (Release Name)      |
| `TLS`...                                               | TLS configurations                          | (provided configurations)|
| `acl`...                                               | ACL configurations                          | (provided configurations)|
| `initContainer`...                                     | Init container configurations               | (provided configurations)|
| `env`...                                                 | List of environment variables               | `[]`                     |

Note: Replace the "..." with specific details or additional rows as required.

### Detailed Configurations

#### Readiness Probe

| Parameter                           | Description                          | Default                 |
|-------------------------------------|--------------------------------------|-------------------------|
| `readinessProbe.enabled`            | Enable the readiness probe           | `false`                 |
| `readinessProbe.initialDelaySeconds`| Delay before probe starts            | `15`                    |
| `readinessProbe.timeoutSeconds`     | Probe timeout                        | `5`                     |
| `readinessProbe.periodSeconds`      | Interval between each probe          | `10`                    |
| `readinessProbe.successThreshold`   | Threshold to consider the probe successful | `1`                  |
| `readinessProbe.failureThreshold`   | Probe failure threshold              | `3`                     |

#### Liveness Probe

| Parameter                           | Description                          | Default                 |
|-------------------------------------|--------------------------------------|-------------------------|
| `livenessProbe.enabled`             | Enable the liveness probe            | `false`                 |
| `livenessProbe.initialDelaySeconds` | Delay before probe starts            | `15`                    |
| `livenessProbe.timeoutSeconds`      | Probe timeout                        | `5`                     |
| `livenessProbe.periodSeconds`       | Interval between each probe          | `10`                    |
| `livenessProbe.successThreshold`    | Threshold to consider the probe successful | `1`                  |
| `livenessProbe.failureThreshold`    | Probe failure threshold              | `3`                     |

#### External Service

| Parameter                       | Description                       | Default                  |
|---------------------------------|-----------------------------------|--------------------------|
| `externalService.enabled`       | Enable external service           | `false`                  |
| `externalService.serviceType`   | Service type (e.g., LoadBalancer) | `LoadBalancer`           |
| `externalService.port`          | External service port             | `6379`                   |
| `externalService.annotations`   | Service annotations               | `{}`                     |

#### Service Monitor

| Parameter                       | Description                       | Default                  |
|---------------------------------|-----------------------------------|--------------------------|
| `serviceMonitor.enabled`        | Enable service monitor            | `false`                  |
| `serviceMonitor.interval`       | Scrape interval                   | `30s`                    |
| `serviceMonitor.scrapeTimeout`  | Scrape timeout                    | `10s`                    |
| `serviceMonitor.namespace`      | Namespace where monitor resides   | `monitoring`             |

#### Redis Exporter

| Parameter                            | Description                         | Default                        |
|--------------------------------------|-------------------------------------|--------------------------------|
| `redisExporter.enabled`              | Enable Redis exporter               | `true`                         |
| `redisExporter.image`                | Redis exporter image                | `quay.io/opstree/redis-exporter:"v1.44.0"` |
| `redisExporter.imagePullPolicy`      | Image pull policy                   | `IfNotPresent`                 |
| `redisExporter.resources`            | Resource limits and requests         | `{}`                           |
| `redisExporter.env`                  | List of environment variables        | `[]`                           |

### Sidecars

| Parameter  | Description                           | Default |
|------------|---------------------------------------|---------|
| `sidecars` | Additional sidecar configurations     | `[]`    |

Example:

```yaml
sidecars:
  - name: "sidecar1"
    image: "image:1.0"
    ...
```

#### Storage Specifications

| Parameter                                   | Description                           | Default                     |
|---------------------------------------------|---------------------------------------|-----------------------------|
| `storageSpec`                               |Volume claim template details          | (provided configurations)   |
| `storageSpec.volumeMount.volume`            | Volume name for the volume mount        | `[]`                      |
| `storageSpec.volumeMount.mountPath`        | Mount paths                              |     []                    |
| `storageSpec.nodeConfVolume`                  | Node configuration volume             | true                     |
| `storageSpec.nodeConfVolumeClaimTemplate` |   Node volume claim template |            (provided configurations)   |

#### TLS

| Parameter                                   | Description                           | Default                     |
|---------------------------------------------|---------------------------------------|-----------------------------|
| `TLS.enabled`                               | Enable TLS                             | `false`                     |
| `TLS.ca`                                    | CA key                                 | `ca.key`                    |
| `TLS.cert`                                  | TLS certificate                        | `tls.crt`                   |
| `TLS.key`                                   | TLS key                                | `tls.key`                   |
| `TLS.secret.secretName`                     | Secret name                            | `redis-tls-cert`            |

#### ACL

| Parameter                                   | Description                           | Default                     |
|---------------------------------------------|---------------------------------------|-----------------------------|
| `acl.enabled`                               | Enable ACL                             | `false`                     |
| `acl.secret`                                | Secret for ACL                         | `""`                        |

#### Init Container

| Parameter                                   | Description                           | Default                     |
|---------------------------------------------|---------------------------------------|-----------------------------|
| `initContainer.enabled`                     | Enable init container                  | `false`                     |
| `initContainer.image`                       | Image for init container               | `""`                        |
| `initContainer.imagePullPolicy`             | Image pull policy                      | `IfNotPresent`              |
| `initContainer.resources`                   | Resource configurations                | `{}`                        |
| `initContainer.env`                         | Environment variables                  | `[]`                        |
| `initContainer.command`                     | Commands for init container            | `[]`                        |
| `initContainer.args`                        | Arguments for the command              | `[]`                        |

#### Environment Variables

| Parameter                                   | Description                           | Default                     |
|---------------------------------------------|---------------------------------------|-----------------------------|
| `env`                                       | List of environment variables          | `[]`                        |

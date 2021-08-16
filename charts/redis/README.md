## Redis

Redis is a key-value based distributed database, this helm chart is for only standalone setup. This helm chart needs [Redis Operator](../redis-operator) inside Kubernetes cluster. The redis definition can be modified or changed by [values.yaml](./values.yaml).

```shell
$ helm repo add ot-helm https://ot-container-kit.github.io/helm-charts/
$ helm install <my-release> ot-helm/redis --namespace <namespace>
```

Redis setup can be upgraded by using `helm upgrade` command:-

```shell
$ helm upgrade <my-release> ot-helm/redis --install --namespace <namespace>
```

For uninstalling the chart:-

```shell
$ helm delete <my-release> --namespace <namespace>
```

### Pre-Requisities

- Kubernetes 1.15+
- Helm 3.X
- Redis Operator 0.7.0

### Parameters

|**Name**|**Value**|**Description**|
|--------|-----------------|-------|
|`redisStandalone.secretName` | redis-secret | Name of the existing secret in Kubernetes |
|`redisStandalone.secretKey` | password |  Name of the existing secret key in Kubernetes |
|`redisStandalone.image` | quay.io/opstree/redis | Name of the redis image |
|`redisStandalone.tag` | v6.2 | Tag of the redis image |
|`redisStandalone.imagePullPolicy` | IfNotPresent | Image Pull Policy of the redis image |
|`redisStandalone.serviceType` | ClusterIP | Kubernetes service type for Redis |
|`redisExporter.enabled` | true | Redis exporter should be deployed or not |
|`redisExporter.image` | quay.io/opstree/redis-exporter | Name of the redis exporter image |
|`redisExporter.tag` | v6.2 | Tag of the redis exporter image |
|`redisExporter.imagePullPolicy` | IfNotPresent | Image Pull Policy of the redis exporter image |
|`nodeSelector` | {} | NodeSelector for redis pods |
|`storageSpec` | {} | Storage configuration for redis setup |
|`securityContext` | {} | Security Context for redis pods |
|`affinity` | {} | Affinity for node and pod for redis pods |
|`tolerations` | {} | Tolerations for redis pods |

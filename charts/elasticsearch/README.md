## Elasticsearch Cluster

Elasticsearch is a poplular NoSQL database which gets used for multiple purpose like:- database, logging, searching, etc. his helm chart needs [Logging Operator](../logging-operator) inside Kubernetes cluster. The elasticsearch definition can be modified or changed by [values.yaml](./values.yaml).

```shell
$ helm repo add ot-helm https://ot-container-kit.github.io/helm-charts/
$ helm install <my-release> ot-helm/elasticsearch --namespace <namespace>
```

Elasticsearch setup can be upgraded by using `helm upgrade` command:-

```shell
$ helm upgrade <my-release> ot-helm/elasticsearch --install --namespace <namespace>
```

For uninstalling the chart:-

```shell
$ helm delete <my-release> --namespace <namespace>
```

### Pre-Requisities

- Kubernetes => 1.15
- Helm => 3.X
- Logging Operator => 0.3.0

### Parameters

| **Name**                         | **Value**       | **Description**                                                    |
|----------------------------------|-----------------|--------------------------------------------------------------------|
| clusterName                      | elastic-prod    | Name of the elasticsearch cluster                                  |
| esVersion                        | 7.17.0          | Major and minor version of elaticsearch                            |
| customConfiguration              | {}              | Additional configuration parameters for elasticsearch              |
| esSecurity.enabled               | true            | To enabled the xpack security of elasticsearch                     |
| esMaster.replicas                | 3               | Number of replicas for elasticsearch master node                   |
| esMaster.storage.storageSize     | 20Gi            | Size of the elasticsearch persistent volume for master             |
| esMaster.storage.accessModes     | [ReadWriteOnce] | Access modes of the elasticsearch persistent volume for master     |
| esMaster.storage.storageClass    | default         | Storage class of the elasticsearch persistent volume for master    |
| esMaster.jvmMaxMemory            | 1Gi             | Java max memory for elasticsearch master node                      |
| esMaster.jvmMinMemory            | 1Gi             | Java min memory for elasticsearch master node                      |
| esMaster.resources               | {}              | Resources for elasticsearch master pods                            |
| esMaster.nodeSelectors           | {}              | Nodeselectors map key-values for elasticsearch master pods         |
| esMaster.affinity                | {}              | Affinity and anit-affinity for elasticsearch master pods           |
| esMaster.tolerations             | {}              | Tolerations and taints for elasticsearch master pods               |
| esData.replicas                  | 3               | Number of replicas for elasticsearch data node                     |
| esData.storage.storageSize       | 50Gi            | Size of the elasticsearch persistent volume for data               |
| esData.storage.accessModes       | [ReadWriteOnce] | Access modes of the elasticsearch persistent volume for data       |
| esData.storage.storageClass      | default         | Storage class of the elasticsearch persistent volume for data      |
| esData.jvmMaxMemory              | 1Gi             | Java max memory for elasticsearch data node                        |
| esData.jvmMinMemory              | 1Gi             | Java min memory for elasticsearch data node                        |
| esData.resources                 | {}              | Resources for elasticsearch data pods                              |
| esData.nodeSelectors             | {}              | Nodeselectors map key-values for elasticsearch data pods           |
| esData.affinity                  | {}              | Affinity and anit-affinity for elasticsearch data pods             |
| esData.tolerations               | {}              | Tolerations and taints for elasticsearch data pods                 |
| esIngestion.replicas             | -               | Number of replicas for elasticsearch ingestion node                |
| esIngestion.storage.storageSize  | -               | Size of the elasticsearch persistent volume for ingestion          |
| esIngestion.storage.accessModes  | -               | Access modes of the elasticsearch persistent volume for ingestion  |
| esIngestion.storage.storageClass | -               | Storage class of the elasticsearch persistent volume for ingestion |
| esIngestion.jvmMaxMemory         | -               | Java max memory for elasticsearch ingestion node                   |
| esIngestion.jvmMinMemory         | -               | Java min memory for elasticsearch ingestion node                   |
| esIngestion.resources            | -               | Resources for elasticsearch ingestion pods                         |
| esIngestion.nodeSelectors        | -               | Nodeselectors map key-values for elasticsearch ingestion pods      |
| esIngestion.affinity             | -               | Affinity and anit-affinity for elasticsearch ingestion pods        |
| esIngestion.tolerations          | -               | Tolerations and taints for elasticsearch ingestion pods            |
| esClient.replicas                | -               | Number of replicas for elasticsearch ingestion node                |
| esClient.storage.storageSize     | -               | Size of the elasticsearch persistent volume for client             |
| esClient.storage.accessModes     | -               | Access modes of the elasticsearch persistent volume for client     |
| esClient.storage.storageClass    | -               | Storage class of the elasticsearch persistent volume for client    |
| esClient.jvmMaxMemory            | -               | Java max memory for elasticsearch client node                      |
| esClient.jvmMinMemory            | -               | Java min memory for elasticsearch client node                      |
| esClient.resources               | -               | Resources for elasticsearch client pods                            |
| esClient.nodeSelectors           | -               | Nodeselectors map key-values for elasticsearch client pods         |
| esClient.affinity                | -               | Affinity and anit-affinity for elasticsearch client pods           |
| esClient.tolerations             | -               | Tolerations and taints for elasticsearch client pods               |

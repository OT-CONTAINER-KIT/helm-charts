## Fluentd

Fluentd is a CNCF graduated project that provides the capability of log shipping as well as parsing. It can ship the logs to multiple destinations like Elasticsearch, Kafka, S3, etc. This helm chart needs [Logging Operator](../logging-operator) inside Kubernetes cluster. The fluentd definition can be modified or changed by [values.yaml](./values.yaml).

```shell
$ helm repo add ot-helm https://ot-container-kit.github.io/helm-charts/
$ helm install <my-release> ot-helm/kibana --namespace <namespace>
```

Fluentd setup can be upgraded by using `helm upgrade` command:-

```shell
$ helm upgrade <my-release> ot-helm/kibana --install --namespace <namespace>
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

| **Name**                         | **Values**             | **Description**                                                 |
|----------------------------------|------------------------|-----------------------------------------------------------------|
| elasticSearchHost                | elasticsearch-master   | Hostname or URL of the elasticsearch server                     |
| indexNameStrategy                | namespace_name         | Strategy for creating indexes like:- namespace_name or pod_name |
| resources                        | {}                     | Resources for fluentd daemonset pods                            |
| nodeSelectors                    | {}                     | Nodeselectors map key-values for fluentd daemonset pods         |
| affinity                         | {}                     | Affinity and anit-affinity for fluentd daemonset pods           |
| tolerations                      | {}                     | Tolerations and taints for fluentd daemonset pods               |
| customConfiguration              | {}                     | Custom configuration parameters for fluentd                     |
| additionalConfiguration          | {}                     | Additional configuration parameters for fluentd                 |
| esSecurity.enabled               | true                   | To enabled the xpack security of fluentd                        |
| esSecurity.elasticSearchPassword | elasticsearch-password | Credentials for elasticsearch authentication                    |

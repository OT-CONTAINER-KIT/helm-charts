## Kibana

Kibana is a visualization tool that can be integrated with elasticsearch. It can be used to visualize logs and create operational dashboards over it. This helm chart needs [Logging Operator](../logging-operator) inside Kubernetes cluster. The kibana definition can be modified or changed by [values.yaml](./values.yaml).

```shell
$ helm repo add ot-helm https://ot-container-kit.github.io/helm-charts/
$ helm install <my-release> ot-helm/kibana --namespace <namespace>
```

Kibana setup can be upgraded by using `helm upgrade` command:-

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

| **Name**                          | **Value**                         | **Description**                                            |
|-----------------------------------|-----------------------------------|------------------------------------------------------------|
| replicas                          | 1                                 | Number of deployment replicas for kibana                   |
| esCluster.esURL                   | https://elasticsearch-master:9200 | Hostname or URL of the elasticsearch server                |
| esCluster.esVersion               | 7.17.0                            | Version of the kibana in pair with elasticsearch           |
| esCluster.clusterName             | elasticsearch                     | Name of the elasticsearch created by elasticsearch crd     |
| resources                         | {}                                | Resources for kibana visualization pods                    |
| nodeSelectors                     | {}                                | Nodeselectors map key-values for kibana visualization pods |
| affinity                          | {}                                | Affinity and anit-affinity for kibana visualization pods   |
| tolerations                       | {}                                | Tolerations and taints for kibana visualization pods       |
| esSecurity.enabled                | true                              | To enabled the xpack security of kibana                    |
| esSecurity.elasticSearchPassword  | elasticsearch-password            | Credentials for elasticsearch authentication               |
| externalService.enabled           | false                             | To create a LoadBalancer service of kibana                 |
| ingress.enabled                   | false                             | To enable the ingress resource for kibana                  |
| ingress.host                      | kibana.opstree.com                | Hostname or URL on which kibana will be exposed            |
| ingress.tls.enabled               | false                             | To enable SSL on kibana ingress resource                   |
| ingress.tls.secret                | tls-secret                        | SSL certificate for kibana ingress resource                |

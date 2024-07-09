# microservice

Basic helm chart for deploying microservices on kubernetes with best practices

![Version: 0.1.2](https://img.shields.io/badge/Version-0.1.2-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.1.2](https://img.shields.io/badge/AppVersion-0.1.2-informational?style=flat-square)

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Ashwani Singh | <ashwani.singh@opstree.com> |  |
| Shikha Tripathi |  |  |

## Installing the Chart

To install the chart with the release name `my-release`:

```console
$ helm install my-release microservice/
```

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| deployment | object | `{"affinity":{},"annotations":{},"environment":{},"image":{"name":"","pullPolicy":"IfNotPresent","tag":""},"livenessProbe":{"failureThreshold":5,"initialDelaySeconds":250,"periodSeconds":10,"successThreshold":1,"timeoutSeconds":5},"nodeSelector":{},"readinessProbe":{"failureThreshold":5,"initialDelaySeconds":30,"periodSeconds":10,"successThreshold":1,"timeoutSeconds":5},"resources":{},"tolerations":[],"volumeMounts":[],"volumes":{"configMaps":null,"enabled":true,"pvc":{"accessModes":["ReadWriteOnce"],"class":"default","enabled":false,"existing_claim":false,"mountPath":"/pv","name":"pvc","size":"1G"}}}` | Object that configures Deployment instance |
| deployment.image | object | `{"name":"","pullPolicy":"IfNotPresent","tag":""}` | Override default container image format |
| global | object | `{"environment":{},"fullnameOverride":"","imagePullSecrets":[],"nameOverride":"","namespace":"default","replicaCount":1}` | global variables   |
| hpa.enabled | bool | `true` |  |
| hpa.maxReplicas | int | `1` |  |
| hpa.minReplicas | int | `1` |  |
| hpa.targetCPU | int | `80` |  |
| hpa.targetMemory | int | `80` |  |
| kubeVersion | string | `""` |  |
| service.annotations | object | `{}` |  |
| service.specs[0].name | string | `"http"` |  |
| service.specs[0].port | int | `80` |  |
| service.type | string | `"ClusterIP"` |  |
| serviceAccount.annotations | object | `{}` |  |
| serviceAccount.automount | bool | `true` |  |
| serviceAccount.create | bool | `false` |  |
| serviceAccount.name | string | `""` |  |

> **_NOTE:_**  Please find the sample helm values yaml in example repository.


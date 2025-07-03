# Worker Deployment Helm Chart

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![AppVersion: 0.1.0](https://img.shields.io/badge/AppVersion-0.1.0-informational?style=flat-square)

A deployment helm chart which will be used to deploy any type of stateless application

**Homepage:** <https://github.com/ot-container-kit/helm-charts>

## Maintainers

| Name              | Email                        | Url                                    |
|-------------------|------------------------------|----------------------------------------|
| iamabhishek-dubey | <abhishek.dubey@opstree.com> | <https://github.com/iamabhishek-dubey> |

## Source Code

* <https://github.com/ot-container-kit/helm-charts>

## Requirements

| Repository                                     | Name | Version |
|------------------------------------------------|------|---------|
| https://ot-container-kit.github.io/helm-charts | base | 0.1.0   |

## Values

| Key                    | Type   | Default                                                                                                                                                                   | Description                                                                                         |
|------------------------|--------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------|
| autoscaling            | object | `{"enabled":false,"maxReplicas":50,"minReplicas":10,"targetCPUUtilizationPercentage":65,"targetMemoryUtilizationPercentage":65}`                                          | Autoscaling properties with target CPU and Memory details                                           |
| base                   | object | `{"image":{"command":[],"pullPolicy":"IfNotPresent","pullSecrets":"","repository":"nginx","tag":"latest"}}`                                                               | Base block to define the inputs for image, secret and configmap env                                 |
| base.image             | object | `{"command":[],"pullPolicy":"IfNotPresent","pullSecrets":"","repository":"nginx","tag":"latest"}`                                                                         | Image block with all image details                                                                  |
| base.image.command     | list   | `[]`                                                                                                                                                                      | Additional command arguments which needs to be passed                                               |
| base.image.pullPolicy  | string | `"IfNotPresent"`                                                                                                                                                          | Default image pull policy                                                                           |
| base.image.pullSecrets | string | `""`                                                                                                                                                                      | Image pull secrets for private repository authentication                                            |
| base.image.repository  | string | `"nginx"`                                                                                                                                                                 | Default image repository                                                                            |
| base.image.tag         | string | `"latest"`                                                                                                                                                                | Default image tag                                                                                   |
| replicaCount           | int    | `2`                                                                                                                                                                       | Number of replicas for deployment, it will be overridden in case autoscaling is enabled             |
| resources              | object | `{}`                                                                                                                                                                      | Kubernetes resource in terms of requests and limits                                                 |
| volumes                | string | `nil`                                                                                                                                                                     | Kubernetes volumes definition which needs to be mounted                                             |

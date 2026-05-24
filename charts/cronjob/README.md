#  Helm Chart for cronjob

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![AppVersion: 0.1.0](https://img.shields.io/badge/AppVersion-0.1.0-informational?style=flat-square)



**Homepage:** <https://github.com/ot-container-kit/helm-charts>

## Maintainers

| Name              | Email                        | 
|-------------------|------------------------------|
| Pritam Kondapratiwar | <pritam.kondapratiwar@opstree.com> |

## Source Code

* <https://github.com/ot-container-kit/helm-charts>

## Requirements

| Repository                                     | Name | Version |
|------------------------------------------------|------|---------|
| https://ot-container-kit.github.io/helm-charts | base | 0.1.0   |

## Values

| Key                    | Type   | Default                                                                                                                                                                   | Description                                                                                         |
|------------------------|--------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------|
| base                   | object | `{"image":{"command":[],"pullPolicy":"IfNotPresent","pullSecrets":"","repository":"nginx","tag":"latest"}}`                                                               | Base block to define the inputs for image, secret and configmap env                                 |
| base.image             | object | `{"command":[],"pullPolicy":"IfNotPresent","pullSecrets":"","repository":"nginx","tag":"latest"}`                                                                         | Image block with all image details                                                                  |
| base.image.command     | list   | `[]`                                                                                                                                                                      | Additional command arguments which needs to be passed                                         
| base.image.pullSecrets | string | `""`                                                                                                                                                                      | Image pull secrets for private repository authentication                                            |
| base.image.repository  | string | `"nginx"`                                                                                                                                                                 | Default image repository                                                                            |
| base.image.tag         | string | `"latest"`                                                                                                                                                                | Default image tag                                                                                   |                                                                                     |
| resources              | object | `{}`                                                                                                                                                                      | Kubernetes resource in terms of requests and limits                                                 |
| volumes                | string | `nil`   

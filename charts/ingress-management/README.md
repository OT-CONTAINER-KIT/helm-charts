# Ingress Management Helm Chart

A simple and reusable Helm chart to manage Kubernetes Gateway API HTTPRoutes for routing traffic to backend services.

This chart helps manage HTTPRoute resources to expose services using Kubernetes Gateway API. You can customize host, path, service, and namespace using values.


## Homepage

[https://github.com/ot-container-kit/helm-charts](https://github.com/ot-container-kit/helm-charts)


## Maintainers

| Name               | URL                                                      |
| ------------------ | -------------------------------------------------------- |
| sharvari-khamkar   | [GitHub](https://github.com/sharvarikhamkar1304)         |


## Source Code

 [GitHub - ot-container-kit/helm-charts](https://github.com/ot-container-kit/helm-charts)


## Requirements

| Repository                                                                                          | Name | Version |
| --------------------------------------------------------------------------------------------------- | ---- | ------- |
| [https://ot-container-kit.github.io/helm-charts](https://ot-container-kit.github.io/helm-charts)   | base | 0.1.0   |


## Values

| **Attribute**     | **Scope**        | **Example**           | **Description**                                                        | **Default**  |
|------------------|------------------|------------------------|------------------------------------------------------------------------|--------------|
| `name`           | Global           | `"my-app"`             | <br><br>    Name of the HTTPRoute and backend service (the app name)<br><br><br>         | `""`         |
| `namespace`      | Global           | `"default"`            | <br><br>    Kubernetes namespace where resources like HTTPRoute will be deployed<br><br><br>   | `""`         |
| `host`           | Routing          | `"app.example.com"`    | <br><br>    Hostname to expose the app<br><br><br>                                       | `""`         |
| `path`           | Routing          | `"/api"`               | <br><br>    Path under the host<br><br><br>                                              | `""`         |
| `service.name`   | Service Config   | `"my-backend-svc"`     | <br><br>    Name of the backend service to which traffic will be routed<br><br><br>     | `""`         |
| `service.kind`   | Service Config   | `"Service"`            | <br><br>    Kind of backend resource (Service by default)<br><br><br>                    | `"Service"`  |
| `service.port`   | Service Config   | `80`                   | <br><br>    Port on which the backend service listens<br><br><br>                        | `80`         |





---

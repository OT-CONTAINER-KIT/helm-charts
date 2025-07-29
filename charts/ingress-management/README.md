
# Ingress Management Helm Chart

A simple and reusable Helm chart to manage Kubernetes Gateway API HTTPRoutes for routing traffic to backend services.

This chart helps manage HTTPRoute resources to expose services using the Kubernetes Gateway API. You can customize host, path, service, and namespace via values.


## Homepage

[https://github.com/ot-container-kit/helm-charts](https://github.com/ot-container-kit/helm-charts)



## Maintainers

| Name             | URL                                           |
| ---------------- | --------------------------------------------- |
| sharvari-khamkar | [GitHub](https://github.com/sharvari-khamkar) |



## Source Code

[GitHub - ot-container-kit/helm-charts](https://github.com/ot-container-kit/helm-charts)



## Requirements

| Repository                                                                                       | Name | Version |
| ------------------------------------------------------------------------------------------------ | ---- | ------- |
| [https://ot-container-kit.github.io/helm-charts](https://ot-container-kit.github.io/helm-charts) | base | 0.1.0   |



## Values

| **Attribute**     | **Scope**        | **Example**           | **Description**                                                        | **Default**  |
|------------------|------------------|------------------------|------------------------------------------------------------------------|--------------|
| <br> `name`  <br>  <br>         |   <br> Global   <br> <br>         |  <br> `"my-app"`  <br>  <br>           |  <br>  Name of the HTTPRoute and backend service (the app name)<br><br>       | `""`         |
| <br> `namespace`  <br>  <br>      |  <br> Global  <br>  <br>          |  <br> `"default"`  <br>  <br>            |  <br> Kubernetes namespace where resources like HTTPRoute will be deployed<br><br> | `""`         |
| <br> `host`  <br>  <br>          | Routing          | `"app.example.com"`    | Hostname to expose the app<br><br>                                     | `""`         |
| <br>`path`   <br>  <br>         | Routing          | `"/api"`               | Path under the host<br><br>                                            | `""`         |
| <br>`service.name` <br>  <br>   | Service Config   | `"my-backend-svc"`     | Name of the backend service to which traffic will be routed<br><br>    | `""`         |
| <br>`service.kind` <br>  <br>   | Service Config   | `"Service"`            | Kind of backend resource (Service by default)<br><br>                  | `"Service"`  |
| <br>`service.port`  <br>  <br>  | Service Config   | `80`                   | Port on which the backend service listens<br><br>                      | `80`         |



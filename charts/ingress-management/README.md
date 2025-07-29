# Ingress Management Helm Chart

A simple and reusable Helm chart to manage Kubernetes Gateway API HTTPRoutes for routing traffic to backend services.

This chart helps manage `HTTPRoute` resources to expose services using Kubernetes Gateway API. You can customize `host`, `path`, `service`, and `namespace` using values.

---

## Homepage

[https://github.com/ot-container-kit/helm-charts](https://github.com/ot-container-kit/helm-charts)

---

## Maintainers

| Name               | URL                                                      |
| ------------------ | -------------------------------------------------------- |
| sharvari-khamkar   | [GitHub](https://github.com/sharvarikhamkar1304)         |

---

## Source Code

 [GitHub - ot-container-kit/helm-charts](https://github.com/ot-container-kit/helm-charts)

---

## Requirements

| Repository                                                                                          | Name | Version |
| --------------------------------------------------------------------------------------------------- | ---- | ------- |
| [https://ot-container-kit.github.io/helm-charts](https://ot-container-kit.github.io/helm-charts)   | base | 0.1.0   |

---

## Values

| Key                    | Type    | Description                                 | Default    |
| ---------------------- | ------- | ------------------------------------------------------------ | ----------- |
| `name`                | string  | Name of the HTTPRoute and backend service (app name)         | `""`        |
| `namespace`           | string  | Kubernetes namespace for deployment                          | `""`        |
| `host`                | string  | Hostname to expose the app (e.g., `app.example.com`)         | `""`        |
| `path`                | string  | Path under the host (e.g., `/`, `/api`)                      | `""`        |
| `service.name`        | string  | Name of the backend service                                  | `""`        |
| `service.kind`        | string  | Kind of the backend resource (default: `Service`)            | `Service`   |
| `service.port`        | int     | Port the backend service listens on                          | `80`        |

---

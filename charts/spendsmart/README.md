# SpendSmart / UnitEconPro Helm Chart

Reusable Helm chart for deploying the SpendSmart / UnitEconPro application components as a single Helm release.

## Scope

This chart deploys the application workloads:

- Backend
- Frontend
- Cloud-Sentry
- Engine refresh CronJob

The chart does **not** deploy or manage:

- ClickHouse
- PostgreSQL
- Keycloak
- AWS infrastructure
- Harbor registry
- OpenTelemetry Operator / Collector
- Ingress controller, DNS, or cluster networking infrastructure

Those dependencies are consumed through existing platform/client resources.

## Chart Structure

```text
spendsmart/
├── Chart.yaml
├── values.yaml
├── README.md
└── templates/
    ├── _helpers.tpl
    ├── serviceaccounts.yaml
    ├── backend/
    │   ├── deployment.yaml
    │   └── service.yaml
    ├── frontend/
    │   ├── configmap.yaml
    │   ├── deployment.yaml
    │   ├── nginx-configmap.yaml
    │   └── service.yaml
    ├── cloudsentry/
    │   ├── deployment.yaml
    │   └── service.yaml
    └── engine/
        └── cronjob.yaml
```

## Components

### Backend

The Backend is deployed as a Kubernetes Deployment and exposed through a ClusterIP Service.

Current configuration includes:

- Image repository/tag
- Private registry pull secret
- Dedicated ServiceAccount
- CPU/memory requests and limits
- OpenTelemetry Python injection annotation
- Liveness probe: `/api/v1/healthz`
- Readiness probe: `/api/v1/readyz`
- Existing Secrets:
  - `encryption-key`
  - `clickhouse`

The readiness endpoint is application-aware and validates backend readiness including ClickHouse connectivity.

### Frontend

The Frontend is deployed as a Deployment and ClusterIP Service.

Runtime configuration is supplied through a ConfigMap and consumed by the container using `envFrom`.

The configurable values are:

- `VITE_API_BASE_URL`
- `VITE_CLOUD_SENTRY_API_BASE_URL`
- `VITE_KEYCLOAK_CLIENT_ID`
- `VITE_KEYCLOAK_REALM`
- `VITE_KEYCLOAK_URL`

The frontend also mounts an Nginx configuration ConfigMap for routing and security headers.

The Nginx configuration includes CSP, HSTS, X-Frame-Options, X-Content-Type-Options, and Referrer-Policy headers.

### Cloud-Sentry

Cloud-Sentry is deployed as a Deployment and ClusterIP Service.

It consumes existing Secrets:

- `aws-access`
- `base-url`
- `gemini-key`
- `postgres-config`

PostgreSQL is external to this chart.

### Engine

The Engine is deployed as a CronJob using the existing validated refresh workflow.

Current defaults:

```text
Schedule: 5 11,23 * * *
Concurrency policy: Forbid
Command: python app.py
Mode: refresh_days
Cloud: aws
Service: all
Days: 2
```

The Engine consumes:

- `clickhouse-db`
- `encryption-key`

The Engine image and schedule are configurable through Helm values.

## Configuration Model

The chart is reusable across environments and clients.

Use the chart's `values.yaml` for defaults and provide a client/environment-specific values file for non-secret overrides.

Example:

```bash
helm upgrade --install spendsmart ./charts/spendsmart   --namespace client-a   --create-namespace   -f client-a-values.yaml
```

A client values file can override items such as:

```yaml
backend:
  image:
    tag: "39"

frontend:
  image:
    tag: "39"

  configMap:
    data:
      VITE_API_BASE_URL: "https://spendsmart-api.client-a.example"
      VITE_CLOUD_SENTRY_API_BASE_URL: "https://cloud-sentry.client-a.example"
      VITE_KEYCLOAK_CLIENT_ID: "uniteconpro"
      VITE_KEYCLOAK_REALM: "client-a"
      VITE_KEYCLOAK_URL: "https://keycloak.client-a.example"

engine:
  schedule: "5 11,23 * * *"
```

Do not place passwords, API keys, access keys, or other credentials in a client values file committed to Git.

## Secrets

The chart intentionally references existing Kubernetes Secrets instead of creating Secret objects containing credentials.

### Backend

```text
clickhouse
encryption-key
```

### Engine

```text
clickhouse-db
encryption-key
```

### Cloud-Sentry

```text
aws-access
base-url
gemini-key
postgres-config
```

### Image Pull

Private registry access is provided through:

```text
harbor-ldc-coe-regcred
```

The Secret must exist in the target namespace before the workloads are started.

## ClickHouse

ClickHouse is an external dependency of the application chart.

The application consumes ClickHouse connection information through Kubernetes Secrets.

Backend:

```yaml
envFrom:
  - secretRef:
      name: encryption-key
  - secretRef:
      name: clickhouse
```

Engine:

```yaml
envFrom:
  - secretRef:
      name: clickhouse-db
  - secretRef:
      name: encryption-key
```

The chart therefore does not care whether the ClickHouse endpoint is centrally hosted or externally managed, provided the expected Secret interface is available.

## OpenTelemetry

The chart preserves the application-level OpenTelemetry injection annotations already used by the workloads:

```yaml
instrumentation.opentelemetry.io/inject-python: observability/otel-instrumentation
```

and:

```yaml
instrumentation.opentelemetry.io/inject-nodejs: observability/otel-instrumentation
```

The OpenTelemetry platform resources themselves are outside the chart boundary.

## RBAC and ServiceAccounts

The chart creates the application's existing ServiceAccounts:

- `uniteconpro-backend`
- `uniteconpro-frontend`
- `cloud-sentry`
- `uniteconpro-sa`

No application Role, RoleBinding, ClusterRole, or ClusterRoleBinding is created by this V1 chart.

The workloads were validated without requiring Kubernetes API resource permissions.

## Client Deployment Flow

```text
Client requirements
        |
        +---- non-secret configuration
        |          |
        |          v
        |    client-a-values.yaml
        |
        +---- credentials / sensitive configuration
                   |
                   v
          approved secret-management process
                   |
                   v
          Kubernetes Secrets
                   |
                   v
             Helm deployment
                   |
        +----------+-----------+-----------+
        |          |           |           |
      Backend    Frontend  Cloud-Sentry  Engine
        |          |           |           |
        +----------+-----------+-----------+
                   |
             External services
          ClickHouse / PostgreSQL /
          Keycloak / AWS / OTEL
```

## Prerequisites

Before installation, verify:

- Supported Kubernetes cluster and namespace access
- Helm 3
- Application images are available and pullable
- Required image-pull Secret exists
- Required application Secrets exist
- ClickHouse connectivity is available
- PostgreSQL is available for Cloud-Sentry
- AWS access is configured according to the target environment
- Keycloak realm/client configuration is available for the frontend
- DNS/Ingress/API routing is configured externally where required
- OpenTelemetry prerequisites exist if instrumentation is enabled

## Validation

Recommended validation order:

```bash
helm lint charts/spendsmart
helm template spendsmart charts/spendsmart
```

Install into a target namespace:

```bash
helm upgrade --install spendsmart charts/spendsmart   --namespace <namespace>   --create-namespace   -f <environment-values>.yaml   --wait
```

Verify:

```bash
kubectl get deploy,svc,pods,cronjob -n <namespace>
```

Backend health checks:

```bash
kubectl port-forward svc/<backend-service> 8000:80 -n <namespace>

curl -i http://127.0.0.1:8000/api/v1/healthz
curl -i http://127.0.0.1:8000/api/v1/readyz
```

Application/API validation should then cover the dashboard and business APIs, followed by Engine Job/log validation.

## Upgrade and Rollback

Upgrade:

```bash
helm upgrade spendsmart charts/spendsmart   --namespace <namespace>   -f <environment-values>.yaml   --wait
```

Review release history:

```bash
helm history spendsmart -n <namespace>
```

Rollback:

```bash
helm rollback spendsmart <REVISION> -n <namespace> --wait
```

## Uninstall

```bash
helm uninstall spendsmart -n <namespace>
```

Uninstalling the chart removes the Helm-managed application resources. Externally managed databases, infrastructure, and separately provisioned Secrets are outside the chart lifecycle.

## Security Notes

- Never commit Secret values to Git.
- Do not store passwords or API keys in `values.yaml`.
- Use an approved secret-management mechanism for credentials.
- Keep private registry credentials outside the chart.
- Review client-specific RBAC, network policy, Pod Security, ingress, and secret-management requirements before production deployment.

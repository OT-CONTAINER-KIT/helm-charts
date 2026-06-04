# BuildPiper Deployment: What Matters And What Does Not

This is the short operational view for your current deployment.

---

## Current Deployment Model

```text
BuildPiper
  -> Helm deploys ai-gateway chart
  -> LiteLLM pod runs in vCluster/Kubernetes
  -> Postgres is external: 192.168.8.39
  -> Redis is external: 192.168.8.78:6379
  -> Domain should be handled by Ingress/Envoy
```

---

## Files You Must Care About

### `values.yaml`

Most important configuration file.

It controls:

- namespace
- LiteLLM image
- replicas/workers
- Postgres external config
- Redis external config
- ingress hostnames
- service type

Important namespace note:

```yaml
namespace: ai-gateway
```

means resources are created in namespace `ai-gateway` because the templates explicitly use `.Values.namespace`.

If BuildPiper/vCluster namespace is `rmes`, set:

```yaml
namespace: rmes
```

or remove `metadata.namespace` from templates and let Helm/BuildPiper control the namespace.

For your setup:

```yaml
postgres:
  enabled: false

redis:
  enabled: false
```

must stay false.

### `templates/litellm-deployment.yaml`

Creates the LiteLLM pod and connects secrets/config.

If pod startup fails, check this file first.

### `templates/litellm-service.yaml`

Creates the internal service:

```text
ai-gateway-litellm-proxy
```

Envoy/Ingress should route traffic to this service.

### `templates/litellm-config.yaml`

Creates LiteLLM config.

Important Redis part:

```yaml
cache_params:
  type: redis
  host: "192.168.8.78"
  port: 6379
  password: os.environ/REDIS_PASSWORD
```

### `templates/ingress-proxy.yaml`

Important only if your chart creates Ingress.

If Envoy routing is fully handled by platform outside your chart, this can be disabled:

```yaml
ingress:
  enabled: false
```

### `templates/ingress-ui.yaml`

Optional. Use this only if you want a separate UI domain.

---

## Files You Usually Do Not Need Now

Because Postgres and Redis are external/shared:

```text
postgres-statefulset.yaml
postgres-service.yaml
postgres-secret.yaml
redis-deployment.yaml
redis-service.yaml
```

These are only for standalone chart mode.

They are disabled by:

```yaml
postgres.enabled: false
redis.enabled: false
```

---

## Secret Strategy

You have two valid strategies.

### Strategy A: Pre-created Kubernetes Secrets

Set:

```yaml
postgres:
  external:
    existingSecret: ai-gateway-db-secret

redis:
  external:
    existingSecret: ai-gateway-redis-secret

litellm:
  existingSecret: ai-gateway-litellm-secret
```

Then create secrets before deployment.

### Strategy B: BuildPiper Secret Variables

Set:

```yaml
postgres:
  external:
    existingSecret: ""
    databaseUrl: "<BuildPiper secret variable>"

redis:
  external:
    existingSecret: ""
    password: "<BuildPiper secret variable>"
```

Then Helm creates Kubernetes secrets during deployment.

Do not mix both patterns unless you know exactly what will render.

---

## Recommended BuildPiper Pattern

Since you are deploying via BuildPiper, prefer this:

```yaml
postgres:
  enabled: false
  external:
    existingSecret: ""
    databaseUrlKey: DATABASE_URL
    databaseUrl: "<BuildPiper DB URL secret>"

redis:
  enabled: false
  external:
    existingSecret: ""
    passwordKey: REDIS_PASSWORD
    password: "<BuildPiper Redis password secret>"
```

This avoids manually creating secrets separately.

But if your organization prefers manually created secrets, use `existingSecret`.

---

## Duplicate Template Warning

Your chart currently has two external Postgres secret templates:

```text
postgres-external-secret.yaml
external-postgres-secret.yaml
```

and two external Redis secret templates:

```text
redis-external-secret.yaml
external-redis-secret.yaml
```

These can create duplicate Kubernetes resources if values overlap.

Recommended for BuildPiper:

Keep/use:

```text
postgres-external-secret.yaml
redis-external-secret.yaml
```

Do not use:

```text
external-postgres-secret.yaml
external-redis-secret.yaml
```

---

## Minimum Healthy Deployment

For the app to work, these must exist:

```text
Deployment: ai-gateway-litellm
Service: ai-gateway-litellm-proxy
ConfigMap: ai-gateway-litellm-config
Secret: DB URL
Secret: Redis password
Secret: LiteLLM master/salt keys
```

For external access, one of these must exist:

```text
Ingress
or
Envoy route managed by platform
```

---

## First Production Sizing

Start simple:

```yaml
litellm:
  replicas: 2
  workers: 2
```

For testing:

```yaml
litellm:
  replicas: 1
  workers: 2
```

Do not over-tune now. First make sure:

- pod starts
- health works
- DB connects
- Redis connects
- domain routes

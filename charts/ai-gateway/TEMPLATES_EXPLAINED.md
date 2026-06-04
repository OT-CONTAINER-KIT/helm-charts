# AI Gateway Helm Templates Explained

This document explains every file inside:

```text
ai-gateway/templates/
```

It also marks which files matter for the current BuildPiper deployment where:

- LiteLLM runs in Kubernetes/vCluster.
- Postgres is external/shared.
- Redis is external/shared.
- BuildPiper passes external credentials.
- We do not want this Helm chart to create its own Postgres or Redis pods.

---

## Quick Importance Table

| Template | Important now? | Why |
|---|---:|---|
| `litellm-deployment.yaml` | Yes | Creates the LiteLLM pod. Most important file. |
| `litellm-service.yaml` | Yes | Gives LiteLLM a stable internal Kubernetes address. |
| `litellm-config.yaml` | Yes | Creates `/app/config.yaml` for LiteLLM. |
| `litellm-secret.yaml` | Maybe | Only used if `litellm.existingSecret` is empty. |
| `ingress-proxy.yaml` | Yes, if domain access is needed | Routes API traffic from domain to LiteLLM service. |
| `ingress-ui.yaml` | Optional | Routes UI traffic to `/ui`. |
| `tls-secret.yaml` | Optional | Only needed if this chart manages TLS certs. |
| `postgres-external-secret.yaml` | Yes for BuildPiper value-based secrets | Creates DB secret from `postgres.external.databaseUrl`. |
| `redis-external-secret.yaml` | Yes for BuildPiper value-based secrets | Creates Redis secret from `redis.external.password`. |
| `external-postgres-secret.yaml` | Not recommended now | Duplicate pattern; can conflict if enabled with `postgres-external-secret.yaml`. |
| `external-redis-secret.yaml` | Not recommended now | Duplicate pattern; can conflict if enabled with `redis-external-secret.yaml`. |
| `postgres-statefulset.yaml` | No | Only used if chart creates its own Postgres. |
| `postgres-service.yaml` | No | Only used with in-chart Postgres. |
| `postgres-secret.yaml` | No | Only used with in-chart Postgres. |
| `redis-deployment.yaml` | No | Only used if chart creates its own Redis. |
| `redis-service.yaml` | No | Only used with in-chart Redis. |
| `NOTES.txt` | Optional | Message printed after Helm install. Not runtime-critical. |

---

## 1. `litellm-deployment.yaml`

This creates the actual LiteLLM application pod.

It defines:

- Docker image: `ghcr.io/berriai/litellm:main-stable`
- Startup command:

```text
--config /app/config.yaml --port 4000 --num_workers 2
```

- Environment variables:
  - `LITELLM_MASTER_KEY`
  - `LITELLM_SALT_KEY`
  - `DATABASE_URL`
  - `REDIS_PASSWORD`
  - optional provider keys

- ConfigMap mount:

```text
/app/config.yaml
```

For your setup, this file is critical because it connects LiteLLM to external Postgres and Redis secrets.

Expected behavior:

```text
LiteLLM pod
  reads DATABASE_URL from Postgres secret
  reads REDIS_PASSWORD from Redis secret
  reads config.yaml from ConfigMap
```

If this file is wrong, pod startup usually fails with:

- `CreateContainerConfigError`
- missing secret
- missing ConfigMap
- DB connection error
- Redis auth error

---

## 2. `litellm-service.yaml`

This creates a Kubernetes Service:

```text
<release-name>-litellm-proxy
```

Example:

```text
ai-gateway-litellm-proxy
```

The Service points to pods with:

```yaml
selector:
  app: litellm
```

Why it matters:

Pods are temporary. Their IP can change. A Service gives the app a stable internal address.

Traffic flow:

```text
Ingress / Envoy
  -> Service: ai-gateway-litellm-proxy:4000
  -> Pod: LiteLLM container:4000
```

For your setup, keep this file.

---

## 3. `litellm-config.yaml`

This creates a ConfigMap:

```text
<release-name>-litellm-config
```

It contains LiteLLM configuration as:

```text
config.yaml
```

This config is mounted inside the pod at:

```text
/app/config.yaml
```

Important current config:

```yaml
litellm_settings:
  cache: true
  cache_params:
    type: redis
    host: "192.168.8.78"
    port: 6379
    password: os.environ/REDIS_PASSWORD
    ttl: 600
```

Why this matters:

- `host` tells LiteLLM where Redis is.
- `password: os.environ/REDIS_PASSWORD` tells LiteLLM to use the Redis password from the pod environment.
- `ttl` controls cache lifetime.

For your setup, keep this file.

---

## 4. `litellm-secret.yaml`

This creates a LiteLLM secret only when:

```yaml
litellm:
  existingSecret: ""
```

It stores:

- `masterKey`
- `saltKey`
- optional provider keys

For production/BuildPiper, better approach:

```yaml
litellm:
  existingSecret: ai-gateway-litellm-secret
  masterKey: ""
  saltKey: ""
```

Then this template will not create a secret. Instead, the deployment reads the already existing `ai-gateway-litellm-secret`.

This is safer because real keys do not live in Git.

---

## 5. `ingress-proxy.yaml`

This creates an Ingress for API/proxy traffic.

Example host:

```yaml
ingress:
  hosts:
    proxy: ai-gateway.example.internal
```

Traffic flow:

```text
https://ai-gateway.example.internal
  -> Ingress rule
  -> Service: ai-gateway-litellm-proxy
  -> LiteLLM pod
```

This is the normal way to access the app.

You do not need port-forwarding if this Ingress/domain is correctly mapped by the platform team.

---

## 6. `ingress-ui.yaml`

This creates a separate Ingress host for LiteLLM UI.

Example:

```text
https://ai-gateway-ui.example.internal/ui
```

It routes to the same backend service:

```text
ai-gateway-litellm-proxy
```

This is optional. If your organization wants only one domain, you can use only the proxy ingress and access:

```text
https://ai-gateway.example.internal/ui
```

---

## 7. `tls-secret.yaml`

This creates a Kubernetes TLS secret when:

```yaml
tls:
  enabled: true
```

It stores:

- `tls.crt`
- `tls.key`

For your setup, this is probably not needed if Envoy/platform ingress already manages certificates.

Use this only if your team asks you to provide TLS cert/key inside this Helm chart.

---

## 8. `postgres-external-secret.yaml`

This creates:

```text
<release-name>-postgres-external-secret
```

when:

```yaml
postgres:
  enabled: false
  external:
    existingSecret: ""
    databaseUrl: "<value passed by BuildPiper>"
```

This is useful when BuildPiper injects the full database URL through a secure variable.

For your BuildPiper setup, this is a good pattern:

```yaml
postgres:
  enabled: false
  external:
    existingSecret: ""
    databaseUrl: "<BuildPiper secret variable>"
```

Then the template creates a Kubernetes Secret with key:

```text
DATABASE_URL
```

---

## 9. `redis-external-secret.yaml`

This creates:

```text
<release-name>-redis-external-secret
```

when:

```yaml
redis:
  enabled: false
  external:
    existingSecret: ""
    password: "<value passed by BuildPiper>"
```

This is useful when BuildPiper injects the Redis password through a secure variable.

Then the template creates a Kubernetes Secret with key:

```text
REDIS_PASSWORD
```

---

## 10. `external-postgres-secret.yaml`

This is another external Postgres secret template.

It builds `DATABASE_URL` using separate values:

```yaml
postgres:
  username:
  database:
  external:
    password:
    host:
    port:
```

Current recommendation:

Do not use this together with `postgres-external-secret.yaml`, because both can create the same secret name:

```text
<release-name>-postgres-external-secret
```

For BuildPiper, prefer `postgres-external-secret.yaml` with full `databaseUrl`.

---

## 11. `external-redis-secret.yaml`

This is another external Redis secret template.

It can create the same secret name as `redis-external-secret.yaml`:

```text
<release-name>-redis-external-secret
```

Current recommendation:

Do not use both. For BuildPiper, prefer `redis-external-secret.yaml`.

---

## 12. `postgres-statefulset.yaml`

This creates an in-chart Postgres pod.

It runs only when:

```yaml
postgres:
  enabled: true
```

For your current organization setup:

```yaml
postgres:
  enabled: false
```

So this file is not used.

Keep it only if you want the chart to support standalone/local deployments later.

---

## 13. `postgres-service.yaml`

This creates a Kubernetes Service for the in-chart Postgres pod.

It is only used when:

```yaml
postgres.enabled: true
```

For your external Postgres setup, it is not used.

---

## 14. `postgres-secret.yaml`

This creates username/password secret for in-chart Postgres.

It is only used when:

```yaml
postgres.enabled: true
```

For your external Postgres setup, it is not used.

---

## 15. `redis-deployment.yaml`

This creates an in-chart Redis pod.

It is only used when:

```yaml
redis.enabled: true
```

For your external Redis setup, it is not used.

---

## 16. `redis-service.yaml`

This creates a Kubernetes Service for the in-chart Redis pod.

It is only used when:

```yaml
redis.enabled: true
```

For your external Redis setup, it is not used.

---

## 17. `NOTES.txt`

This prints helpful text after Helm install/upgrade.

It does not create runtime resources.

It is useful for humans, not required by Kubernetes.

---

## Recommended Cleanup For BuildPiper

For the cleanest BuildPiper-only chart, keep:

```text
litellm-deployment.yaml
litellm-service.yaml
litellm-config.yaml
litellm-secret.yaml
ingress-proxy.yaml
ingress-ui.yaml
tls-secret.yaml
postgres-external-secret.yaml
redis-external-secret.yaml
NOTES.txt
```

Optional to remove or archive if you no longer need standalone mode:

```text
postgres-statefulset.yaml
postgres-service.yaml
postgres-secret.yaml
redis-deployment.yaml
redis-service.yaml
external-postgres-secret.yaml
external-redis-secret.yaml
```

If you keep them, ensure:

```yaml
postgres.enabled: false
redis.enabled: false
```

and avoid passing both:

```yaml
postgres.external.databaseUrl
postgres.external.password
redis.external.password
```

in a way that makes duplicate secret templates render the same resource.


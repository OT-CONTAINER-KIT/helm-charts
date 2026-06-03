# BuildPiper Helm Deployment Steps

> This chart is prepared for LiteLLM using external organization Postgres and Redis.
> Passwords must be stored as Kubernetes Secrets, not in `values.yaml`.

---

## External Services

Postgres:

```text
host: 192.168.8.39
port: 5432
database: ai-gateway-db
user: ai-db-user
```

Redis:

```text
host: 192.168.8.78
port: 6379
password: stored in Kubernetes Secret
```

---

## 1. Confirm Deployment Namespace

Use the exact namespace where BuildPiper deploys this chart.

From the pod describe output, the vCluster namespace is:

```text
rems
```

The host cluster shows the pod under:

```text
coe-dev
```

But secrets must exist in the **same BuildPiper/vCluster namespace as the Helm release**. For this deployment, that appears to be `rems`, not `ai-gateway`.

If `rems` already exists, do not create it again. Otherwise:

```bash
kubectl create namespace rems
```

If BuildPiper is using a different app namespace, replace `rems` in all commands below with that namespace.

---

## 2. Create Postgres Secret

Create this secret before Helm deployment:

```bash
kubectl create secret generic ai-gateway-db-secret \
  -n rems \
  --from-literal=DATABASE_URL='postgresql://ai-db-user:<postgres-password>@192.168.8.39:5432/ai-gateway-db'
```

Replace `<postgres-password>` with the real password.

If the password contains special characters like `@`, `#`, `/`, `:`, or `%`, URL-encode it before putting it inside `DATABASE_URL`.

---

## 3. Create Redis Secret

```bash
kubectl create secret generic ai-gateway-redis-secret \
  -n rems \
  --from-literal=REDIS_PASSWORD='<redis-password>'
```

Replace `<redis-password>` with the real Redis password.

---

## 4. Optional: Create LiteLLM Secret Manually

The chart can create the LiteLLM master/salt secret from `values.yaml`, but for production-like deployment this is better:

```bash
kubectl create secret generic ai-gateway-litellm-secret \
  -n rems \
  --from-literal=masterKey='sk-master-<generate-a-strong-value>' \
  --from-literal=saltKey='sk-salt-<generate-a-strong-value>'
```

Then set this in `values.yaml`:

```yaml
litellm:
  existingSecret: ai-gateway-litellm-secret
```

If you do not set `existingSecret`, the chart will create `RELEASE_NAME-litellm-secret` using `masterKey` and `saltKey` from `values.yaml`.

---

## 5. Current Chart Values

This chart is already configured with:

```yaml
postgres:
  enabled: false
  external:
    host: 192.168.8.39
    port: 5432
    existingSecret: ai-gateway-db-secret
    databaseUrlKey: DATABASE_URL

redis:
  enabled: false
  external:
    host: 192.168.8.78
    port: 6379
    existingSecret: ai-gateway-redis-secret
    passwordKey: REDIS_PASSWORD
```

LiteLLM Redis config is also already pointing to:

```yaml
host: 192.168.8.78
port: 6379
password: os.environ/REDIS_PASSWORD
```

---

## 6. Deploy With Helm

Example:

```bash
helm upgrade --install ai-gateway ./ai-gateway \
  -n rems
```

In BuildPiper, select/use the `ai-gateway` chart folder and deploy with the same namespace where the secrets exist.

If BuildPiper cannot use pre-created Kubernetes Secrets, set `postgres.external.existingSecret` and `redis.external.existingSecret` to empty and inject these values securely through BuildPiper secret variables:

```yaml
postgres:
  external:
    existingSecret: ""
    password: "<postgres-password>"

redis:
  external:
    existingSecret: ""
    password: "<redis-password>"
```

Pre-created Kubernetes Secrets are still the preferred path.

---

## 7. Validate

```bash
kubectl get pods -n rems
```

```bash
kubectl logs deploy/ai-gateway-litellm -n rems
```

```bash
kubectl port-forward svc/ai-gateway-litellm-proxy -n rems 4000:4000
```

```bash
curl http://localhost:4000/health/liveliness
```

Expected:

```text
I'm alive!
```

---

## Most Common Errors

| Error | Fix |
|---|---|
| `secret "ai-gateway-db-secret" not found` | Create the Postgres secret in the same namespace |
| `secret "ai-gateway-redis-secret" not found` | Create the Redis secret in the same namespace |
| `secret "ai-gateway-litellm-secret-...vcluster" not found` | Create `ai-gateway-litellm-secret` in the BuildPiper/vCluster namespace, not the host namespace |
| `password authentication failed` | Check DB username/password and URL encoding |
| `permission denied for schema public` | Grant `ai-db-user` create/usage privileges on `ai-gateway-db` |
| Redis auth error | Check Redis password secret and Redis password requirement |
| Connection timeout | Check network access from K8s namespace to `192.168.8.39` and `192.168.8.78` |

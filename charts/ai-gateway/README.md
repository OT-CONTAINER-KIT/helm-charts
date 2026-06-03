# BuildPiper LiteLLM Helm Chart

This chart deploys LiteLLM using organization-managed external Postgres and Redis.

External services configured in `values.yaml`:

```text
Postgres: 192.168.8.39:5432
Database: ai-gateway-db
User: ai-db-user

Redis: 192.168.8.78:6379
```

Passwords are intentionally not stored in this chart. Create these Kubernetes Secrets before deployment:

```text
ai-gateway-db-secret      key: DATABASE_URL
ai-gateway-redis-secret   key: REDIS_PASSWORD
```

Follow [BUILDPIPER_DEPLOYMENT_STEPS.md](BUILDPIPER_DEPLOYMENT_STEPS.md) before deploying.


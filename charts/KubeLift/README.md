# KubeLift Helm Chart

Single Helm chart to deploy KubeLift backend, frontend, and consumer from one folder.

## Chart Location

- `charts/KubeLift`

## Deploy

```bash
helm upgrade --install kubelift charts/KubeLift -n kubelift --create-namespace
```

## Toggle Services

You can control services in two ways:

- Per-service switch: `backend.enabled`, `frontend.enabled`, `consumer.enabled`
- Tag switch: `tags.backend`, `tags.frontend`, `tags.consumer`

A service is deployed only when both are `true`.

## Examples

### 1) Deploy all services

```bash
helm upgrade --install kubelift charts/KubeLift -n kubelift --create-namespace \
  --set backend.enabled=true \
  --set frontend.enabled=true \
  --set consumer.enabled=true \
  --set tags.backend=true \
  --set tags.frontend=true \
  --set tags.consumer=true
```

### 2) Deploy only backend

```bash
helm upgrade --install kubelift charts/KubeLift -n kubelift --create-namespace \
  --set backend.enabled=true \
  --set frontend.enabled=false \
  --set consumer.enabled=false \
  --set tags.backend=true \
  --set tags.frontend=false \
  --set tags.consumer=false
```

### 3) Deploy only frontend

```bash
helm upgrade --install kubelift charts/KubeLift -n kubelift --create-namespace \
  --set backend.enabled=false \
  --set frontend.enabled=true \
  --set consumer.enabled=false \
  --set tags.backend=false \
  --set tags.frontend=true \
  --set tags.consumer=false
```

### 4) Deploy only consumer

```bash
helm upgrade --install kubelift charts/KubeLift -n kubelift --create-namespace \
  --set backend.enabled=false \
  --set frontend.enabled=false \
  --set consumer.enabled=true \
  --set tags.backend=false \
  --set tags.frontend=false \
  --set tags.consumer=true
```

### 5) Deploy backend + frontend

```bash
helm upgrade --install kubelift charts/KubeLift -n kubelift --create-namespace \
  --set backend.enabled=true \
  --set frontend.enabled=true \
  --set consumer.enabled=false \
  --set tags.backend=true \
  --set tags.frontend=true \
  --set tags.consumer=false
```

### 6) Deploy backend + consumer

```bash
helm upgrade --install kubelift charts/KubeLift -n kubelift --create-namespace \
  --set backend.enabled=true \
  --set frontend.enabled=false \
  --set consumer.enabled=true \
  --set tags.backend=true \
  --set tags.frontend=false \
  --set tags.consumer=true
```

### 7) Deploy frontend + consumer

```bash
helm upgrade --install kubelift charts/KubeLift -n kubelift --create-namespace \
  --set backend.enabled=false \
  --set frontend.enabled=true \
  --set consumer.enabled=true \
  --set tags.backend=false \
  --set tags.frontend=true \
  --set tags.consumer=true
```

## Values File Override (recommended)

Create an override file and use `-f`:

```bash
helm upgrade --install kubelift charts/KubeLift -n kubelift --create-namespace -f my-values.yaml
```

Example `my-values.yaml` for backend + frontend:

```yaml
tags:
  backend: true
  frontend: true
  consumer: false

backend:
  enabled: true
frontend:
  enabled: true
consumer:
  enabled: false
```

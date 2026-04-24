# ClickHouse Helm Chart

This Helm chart deploys a generic ClickHouse instance on Kubernetes.

## Features
- 4 CPU, 8Gi RAM (configurable)
- Persistent storage (20Gi by default)
- Default admin user: `clickhouse` / `clickhouse`
- Application DB: `kubelift`, user: `kubelift`, password: `kubelift`
- Exposes HTTP (8123) and native (9000) ports
- StatefulSet for stable storage and identity

## Quick Start

### 1. (Optional) Create a Namespace
```
kubectl create namespace my-namespace
```

### 2. Install the Chart (default namespace)
```
helm install clickhouse ./clickhouse
```

### 3. Access ClickHouse
- **Within default namespace:**
  - Host: `clickhouse`
  - HTTP Port: `8123`
  - Native Port: `9000`
- **From another namespace:**
  - Host: `clickhouse.default.svc.cluster.local`

### 4. Application Connection Example
To connect your application to the `kubelift` database as the `kubelift` user:
- **Host:** `clickhouse` (or `clickhouse.default.svc.cluster.local` from another namespace)
- **Port:** `9000` (native) or `8123` (HTTP)
- **Database:** `kubelift`
- **User:** `kubelift`
- **Password:** `kubelift`

**Example connection string (native protocol):**
```
clickhouse://kubelift:kubelift@clickhouse:9000/kubelift
```

**Example connection string (HTTP):**
```
http://kubelift:kubelift@clickhouse:8123/kubelift
```

### 5. Admin Access
- **User:** `clickhouse`
- **Password:** `clickhouse`

## Customization
- **Resources:**
  - 4 CPU, 8Gi RAM (default)
- **Storage:**
  - 20Gi (default)
- **Users/DB:**
  - Set in `values.yaml` under `clickhouse:`

## Uninstall
```
helm uninstall clickhouse --namespace default
```

---
For more details, see the [templates/](templates/) directory.

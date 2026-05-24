# PostgreSQL 16 Helm Chart

This Helm chart deploys a production-ready PostgreSQL 16 instance on Kubernetes.

## Features
- StatefulSet for stable storage
- Persistent storage (PVC)
- Secure password management via Secret
- Liveness and readiness probes
- Init script for extra DB/user (idempotent)
- Configurable resources and storage

## Quick Start


### 1. (Optional) Create a Namespace
If you want to use a custom namespace:
```
kubectl create namespace my-namespace
```

### 2. Install from Your GitHub Repo (Specific Branch)
Clone the repo and checkout the desired branch:
```
git clone --branch postgres https://github.com/OT-CONTAINER-KIT/helm-charts.git
cd helm-charts/charts/postgres-16
helm install postgres-16 .
```

### 2. Install the Chart (default namespace)
```
helm install postgres-16 ./postgres-16
```

### 3. Access PostgreSQL
- **Within default namespace:**
  - Host: `postgres-16`
  - Port: `5432`
- **From another namespace:**
  - Host: `postgres-16.default.svc.cluster.local`
  - Port: `5432`

### 4. Application Environment Variables
Set these in your application to connect to the database:
```

POSTGRES_HOST=postgres-16
POSTGRES_PORT=5432
POSTGRES_DB=postgres
POSTGRES_USER=postgres
POSTGRES_PASSWORD=StrongPassword

If your app is in a different namespace, use:

POSTGRES_HOST=postgres-16.default.svc.cluster.local

## Customization
- **Resources:**
  - 2 CPU, 4Gi RAM (default)
- **Storage:**
  - 20Gi (default)
- **Database/User:**
  - Set in `values.yaml` under `postgresql:`

## Uninstall
```
helm uninstall postgres-16 --namespace kubelift
```

---
For more details, see the [NOTES.txt](templates/NOTES.txt) after installation.

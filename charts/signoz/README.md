# SigNoz Helm Deployment Guid

This guide provides step-by-step instructions to deploy SigNoz on a Kubernetes cluster using an optimized `values.yaml`. It also includes a full parameter explanation in tabular format.

---

## About This `values.yaml`

This `values.yaml` is a lean and optimized version crafted for production use in Kubernetes.
---

## ⚙️ Configuration Parameters Explained

| Parameter Path                    | Description                                     | Default / Example                |
| --------------------------------- | ----------------------------------------------- | -------------------------------- |
| `global.storageClass`             | Default storage class for persistent volumes    | `managed-csi`                    |
| `global.cloud`                    | Cloud provider environment                      | `azure`                          |
| `clickhouse.enabled`              | Enables ClickHouse deployment                   | `true`                           |
| `clickhouse.cluster`              | Name of the ClickHouse cluster (≤15 chars)      | `signozch`                       |
| `clickhouse.layout.shardsCount`   | Number of shards                                | `1`                              |
| `clickhouse.layout.replicasCount` | Number of replicas                              | `1`                              |
| `clickhouse.user`                 | ClickHouse admin user                           | `admin`                          |
| `clickhouse.password`             | ClickHouse admin password                       | `27ff0399-...fb9`                |
| `clickhouse.persistence.enabled`  | Enables persistent volume for ClickHouse        | `true`                           |
| `clickhouse.persistence.size`     | Size of ClickHouse PVC                          | `8Gi`                            |
| `clickhouse.zookeeper.enabled`    | Enables Zookeeper (required for ClickHouse HA)  | `true`                           |
| `zookeeper.enabled`               | Enables standalone Zookeeper                    | `true`                           |
| `zookeeper.persistence.size`      | Size of Zookeeper PVC                           | `8Gi`                            |
| `signoz.replicaCount`             | Number of SigNoz API pod replicas               | `1`                              |
| `signoz.image.tag`                | SigNoz backend version                          | `v0.86.2`                        |
| `signoz.service.port`             | Port for the SigNoz service                     | `8080`                           |
| `signoz.configVars.storage`       | Backend storage type                            | `clickhouse`                     |
| `signoz.persistence.size`         | SigNoz DB PVC size                              | `1Gi`                            |
| `schemaMigrator.enabled`          | Enables the schema migrator job                 | `true`                           |
| `schemaMigrator.initContainers`   | Wait and readiness init containers              | `enabled` (as per default chart) |
| `otelCollector.replicaCount`      | Number of collector replicas                    | `1`                              |
| `otelCollector.config.*`          | Detailed OpenTelemetry receiver/exporter config | See values.yaml                  |

---

## Deployment Procedure

### 1. Add SigNoz Helm Repo

```bash
helm repo add ot-helm https://ot-container-kit.github.io/helm-charts/
helm repo update
```

### 2. Create Namespace

```bash
kubectl create namespace signoz
```

### 3. Apply Helm Chart with Optimized values.yaml

```bash
helm upgrade --install signoz signoz/signoz \
  -n signoz \
  -f values.yaml \
  --wait
```

### 4. Verify Everything is Running

```bash
kubectl get pods -n signoz
kubectl get pvc -n signoz
kubectl get chi -n signoz
```

Expected pod output:

* `chi-signozch-*` (ClickHouse) → Running
* `signoz-*` (backend) → Running
* `signoz-otel-collector-*` → Running
* `signoz-schema-migrator-*` → Completed

---

##  Accessing SigNoz UI

If you haven’t exposed it via Ingress or LoadBalancer, you can port-forward:

```bash
kubectl port-forward svc/signoz 8080:8080 -n signoz
```

Then open: [http://localhost:8080](http://localhost:8080)

---

## 💡 Next Steps

* Configure OTLP exporters in your app to send traces & metrics
* Optionally enable Ingress, TLS, or SSO in your values
* Monitor ClickHouse health under `/signoz/system` UI tab

---

For any issues, visit [https://signoz.io/docs](https://signoz.io/docs) or raise a GitHub issue at [https://github.com/SigNoz/signoz](https://github.com/SigNoz/signoz)

---


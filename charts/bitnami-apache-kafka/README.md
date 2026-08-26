# Apache Kafka Helm Chart

This Helm chart deploys a production-ready Apache Kafka (with Zookeeper) cluster on Kubernetes.

## Features
- 1 Kafka broker (scalable)
- 1 Zookeeper node
- Persistent storage for both Kafka and Zookeeper
- Liveness and readiness probes
- Topic auto-creation via Job (optional)
- Customizable resources and storage

## Quick Start

### 1. Create the Namespace
```
kubectl create namespace kubelift
```

### 2. Install the Chart
```
helm install apache-kafka ./apache-kafka --namespace kubelift
```

### 3. Access Kafka
- **Within kubelift namespace:**
  - Broker address: `apache-kafka:9092`
- **From another namespace:**
  - Broker address: `apache-kafka.kubelift.svc.cluster.local:9092`


### 4. Automatic Topic Creation (Optional)
To automatically create topics at install time, define them in `values.yaml`:

```yaml
topics:
  - name: my-topic
    partitions: 3
    replicationFactor: 1
    config: {}
```

The chart will run a Kubernetes Job to create these topics using the Kafka CLI. This works only for topics defined at install/upgrade time.

## Customization
- **Resources:**
  - Kafka: 2 CPU, 4Gi RAM (default)
  - Zookeeper: 2 CPU, 4Gi RAM (default)
- **Storage:**
  - Kafka: 5Gi (default)
  - Zookeeper: 5Gi (default)
- **Consumer Groups:**
  - Define in `values.yaml` under `consumerGroups:`

## Uninstall
```
helm uninstall apache-kafka --namespace kubelift
```

---
For more details, see the [NOTES.txt](templates/NOTES.txt) after installation.

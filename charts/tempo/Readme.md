# Monitoring Setup with Helm
This document provides detailed instructions for setting up Tempo and OpenTelemetry in a Kubernetes cluster using Helm charts. Follow these commands to deploy Tempo, OpenTelemetry, and their associated components.

# For OpenTelemetry:
## 1. Apply Custom Resource Definitions (CRDs)

Run the following commands to apply each CRD:

```bash
kubectl apply --server-side=true -f https://raw.githubusercontent.com/prometheus-community/helm-charts/kube-prometheus-stack-61.5.0/charts/kube-prometheus-stack/charts/crds/crds/crd-alertmanagers.yaml
kubectl apply --server-side=true -f https://raw.githubusercontent.com/prometheus-community/helm-charts/kube-prometheus-stack-61.5.0/charts/kube-prometheus-stack/charts/crds/crds/crd-alertmanagerconfigs.yaml
kubectl apply --server-side=true -f https://raw.githubusercontent.com/prometheus-community/helm-charts/kube-prometheus-stack-61.5.0/charts/kube-prometheus-stack/charts/crds/crds/crd-podmonitors.yaml
kubectl apply --server-side=true -f https://raw.githubusercontent.com/prometheus-community/helm-charts/kube-prometheus-stack-61.5.0/charts/kube-prometheus-stack/charts/crds/crds/crd-probes.yaml
kubectl apply --server-side=true -f https://raw.githubusercontent.com/prometheus-community/helm-charts/kube-prometheus-stack-61.5.0/charts/kube-prometheus-stack/charts/crds/crds/crd-prometheusagents.yaml
kubectl apply --server-side=true -f https://raw.githubusercontent.com/prometheus-community/helm-charts/kube-prometheus-stack-61.5.0/charts/kube-prometheus-stack/charts/crds/crds/crd-prometheuses.yaml
kubectl apply --server-side=true -f https://raw.githubusercontent.com/prometheus-community/helm-charts/kube-prometheus-stack-61.5.0/charts/kube-prometheus-stack/charts/crds/crds/crd-prometheusrules.yaml
kubectl apply --server-side=true -f https://raw.githubusercontent.com/prometheus-community/helm-charts/kube-prometheus-stack-61.5.0/charts/kube-prometheus-stack/charts/crds/crds/crd-scrapeconfigs.yaml
kubectl apply --server-side=true -f https://raw.githubusercontent.com/prometheus-community/helm-charts/kube-prometheus-stack-61.5.0/charts/kube-prometheus-stack/charts/crds/crds/crd-servicemonitors.yaml
kubectl apply --server-side=true -f https://raw.githubusercontent.com/prometheus-community/helm-charts/kube-prometheus-stack-61.5.0/charts/kube-prometheus-stack/charts/crds/crds/crd-thanosrulers.yaml
```
## 2. Update Helm Chart Dependencies
```
helm dep update
```
Updates Helm chart dependencies.

## 3. Create a Namespace for Observability
```
kubectl create ns observability
```
Creates a Kubernetes namespace named observability 

## 4. Render chart templates locally and apply
```
helm template --name-template=otel . -n observability | k apply -f -
```

# For Tempo:
## 1. Apply Custom Resource Definitions (CRDs)

Run the following commands to apply each CRD:

```bash
kubectl apply --server-side=true -f https://raw.githubusercontent.com/prometheus-community/helm-charts/kube-prometheus-stack-61.5.0/charts/kube-prometheus-stack/charts/crds/crds/crd-alertmanagers.yaml
kubectl apply --server-side=true -f https://raw.githubusercontent.com/prometheus-community/helm-charts/kube-prometheus-stack-61.5.0/charts/kube-prometheus-stack/charts/crds/crds/crd-alertmanagerconfigs.yaml
kubectl apply --server-side=true -f https://raw.githubusercontent.com/prometheus-community/helm-charts/kube-prometheus-stack-61.5.0/charts/kube-prometheus-stack/charts/crds/crds/crd-podmonitors.yaml
kubectl apply --server-side=true -f https://raw.githubusercontent.com/prometheus-community/helm-charts/kube-prometheus-stack-61.5.0/charts/kube-prometheus-stack/charts/crds/crds/crd-probes.yaml
kubectl apply --server-side=true -f https://raw.githubusercontent.com/prometheus-community/helm-charts/kube-prometheus-stack-61.5.0/charts/kube-prometheus-stack/charts/crds/crds/crd-prometheusagents.yaml
kubectl apply --server-side=true -f https://raw.githubusercontent.com/prometheus-community/helm-charts/kube-prometheus-stack-61.5.0/charts/kube-prometheus-stack/charts/crds/crds/crd-prometheuses.yaml
kubectl apply --server-side=true -f https://raw.githubusercontent.com/prometheus-community/helm-charts/kube-prometheus-stack-61.5.0/charts/kube-prometheus-stack/charts/crds/crds/crd-prometheusrules.yaml
kubectl apply --server-side=true -f https://raw.githubusercontent.com/prometheus-community/helm-charts/kube-prometheus-stack-61.5.0/charts/kube-prometheus-stack/charts/crds/crds/crd-scrapeconfigs.yaml
kubectl apply --server-side=true -f https://raw.githubusercontent.com/prometheus-community/helm-charts/kube-prometheus-stack-61.5.0/charts/kube-prometheus-stack/charts/crds/crds/crd-servicemonitors.yaml
kubectl apply --server-side=true -f https://raw.githubusercontent.com/prometheus-community/helm-charts/kube-prometheus-stack-61.5.0/charts/kube-prometheus-stack/charts/crds/crds/crd-thanosrulers.yaml
```
## 2. Update Helm Chart Dependencies
```
helm dep update
```
Updates Helm chart dependencies.

## 3. Create a Namespace for Observability
```
kubectl get ns observability > /dev/null 2>&1 || kubectl create ns observability
```
Creates a Kubernetes namespace named observability if it does not already exist.

## 4. Render chart templates locally and apply
```
helm template --name-template=tracing . -n observability | k apply -f -
```

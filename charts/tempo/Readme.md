# Monitoring Setup with Helm
This document provides detailed instructions for setting up Tempo and OpenTelemetry in a Kubernetes cluster using Helm charts. Follow these commands to deploy Tempo, OpenTelemetry, and their associated components.

# For OpenTelemetry:
## 1. Update Helm Chart Dependencies
```
helm dep update
```
Updates Helm chart dependencies.

## 2. Create a Namespace for Observability
```
kubectl create ns observability
```
Creates a Kubernetes namespace named observability 

## 3. Render chart templates locally and apply
```
helm template --name-template=otel . -n observability | k apply -f -
```

# For Tempo:

## 1. Update Helm Chart Dependencies
```
helm dep update
```
Updates Helm chart dependencies.

## 2. Create a Namespace for Observability
```
kubectl get ns observability > /dev/null 2>&1 || kubectl create ns observability
```
Creates a Kubernetes namespace named observability if it does not already exist.

## 3. Render chart templates locally and apply
```
helm template --name-template=tracing . -n observability | k apply -f -
```

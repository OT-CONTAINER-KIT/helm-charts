# Prometheus Monitoring Setup with Helm

This document provides detailed instructions for setting up Prometheus monitoring in a Kubernetes cluster using Helm charts. Follow these commands to deploy Prometheus and its associated components.

## 1. Apply Custom Resource Definitions (CRDs)

Before deploying Prometheus, you need to apply various Custom Resource Definitions (CRDs). CRDs extend Kubernetes capabilities to support custom resources used by Prometheus.

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
Updates Helm chart dependencies. This command ensures that any dependencies required by your Helm chart are up-to-date, which is crucial before deploying or upgrading your chart.

## 3. Create a Namespace for Monitoring

```
kubectl create ns monitoring
```
Creates a Kubernetes namespace named monitoring. This namespace is used to isolate monitoring-related resources such as Prometheus and Grafana, ensuring they do not interfere with other resources in the cluster.

## 4. Template and Apply Helm Chart
```
helm template --name-template=monitoring . -n monitoring -f values.yaml | kubectl apply -f -
```
Performs two actions:

 ```helm template``` Generates Kubernetes manifest files from the Helm chart templates, using values specified in ```values.yaml```. The ```--name-template=monitoring``` option sets the name for the Helm release.

```kubectl apply``` Applies the generated Kubernetes manifests to the cluster. The ```-f -``` option reads the manifests from standard input (piped from the helm template output) and applies them.
This command effectively deploys the Prometheus monitoring stack with the configurations specified in values.yaml.

## 5. Verify Deployed Services
```
kubectl get svc -n monitoring
```
Lists all the services in the monitoring namespace. This command provides information about the services deployed, including their names, cluster IPs, and ports.


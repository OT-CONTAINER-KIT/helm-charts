# API Gateway Platform (Gateway API)

This Helm chart installs a **Gateway API–based platform layer** for Kubernetes.

## Installed resources
- Namespace
- GatewayClass
- Gateway

## Not included
- Routes (HTTPRoute)
- Authentication
- Rate limiting

These are intentionally managed separately.

## Prerequisites

Install Gateway API CRDs first:

```bash
#Install CRDs
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.1.0/standard-install.yaml
#Install api-gatway after choosing gateway type in values.yaml 
helm install api-gateway ./charts/api-gateway \
  --namespace kong \
  --create-namespace
#Configuration
controller:
  type: kong   # kong | istio | aws | gcp

gateway:
  name: platform-gateway
  className: platform-gateway-class
  namespace: kong


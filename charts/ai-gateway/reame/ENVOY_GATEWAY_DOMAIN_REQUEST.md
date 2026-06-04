# Envoy Gateway Domain Request

Please expose the LiteLLM AI Gateway through the platform Envoy Gateway.

## Application Backend

- Namespace: `ai-gateway`
- Kubernetes Service: `ai-gateway-litellm-proxy`
- Service FQDN: `ai-gateway-litellm-proxy.ai-gateway.svc.cluster.local`
- Service port: `4000`
- Protocol from Envoy to service: `HTTP`
- Health check path: `/health/liveliness`

## Public Route

- Required hostname: `ai-gateway.opstree`
- Required URL: `https://ai-gateway.opstree/ui`
- Route path prefix: `/`

Route `/`, not only `/ui`, because the LiteLLM UI can call APIs and static assets outside the `/ui` path.

## DNS / IP Ownership

The DNS record for `ai-gateway.opstree` should point to the Envoy Gateway external LoadBalancer IP or hostname.

The application team should not provide a pod IP, ClusterIP, or node IP for DNS:

- Pod IP changes when pods restart.
- ClusterIP is internal-only.
- Node IP bypasses the platform Gateway.

The platform/Envoy team should provide the external LoadBalancer IP or hostname for DNS.

## If App Team Must Create HTTPRoute

Please provide:

- Envoy Gateway name
- Envoy Gateway namespace
- Confirmation that Gateway API CRDs are installed
- Confirmation that this Gateway allows routes from namespace `ai-gateway`
- TLS termination details

After that, set these Helm values:

```yaml
gatewayApi:
  enabled: true
  hostname: ai-gateway.opstree
  parentRef:
    name: "<envoy-gateway-name>"
    namespace: "<envoy-gateway-namespace>"
  pathPrefix: /

ingress:
  enabled: false

service:
  type: ClusterIP
```

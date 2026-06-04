# Networking, Ingress, vCluster, And Envoy Explained

This document explains how traffic reaches LiteLLM after Helm/BuildPiper deployment.

---

## The Simple Picture

Your LiteLLM app runs inside Kubernetes as a pod.

The pod listens on:

```text
4000
```

But users do not normally call the pod directly.

The normal flow is:

```text
Browser / Client / Backend App
  |
  v
Domain name
  |
  v
Envoy / Ingress Gateway
  |
  v
Kubernetes Ingress rule
  |
  v
Kubernetes Service
  |
  v
LiteLLM Pod :4000
```

---

## What Is A Pod?

A pod is where your LiteLLM container actually runs.

Example:

```text
ai-gateway-litellm-884d4c7bf-xxxxx
```

Pods are temporary. Kubernetes can delete and recreate them anytime during:

- rollout
- node restart
- crash recovery
- scaling

So you should not depend on pod IP directly.

---

## What Is A Service?

A Service gives a stable internal address to a group of pods.

Your chart creates:

```text
ai-gateway-litellm-proxy
```

It points to pods with:

```yaml
selector:
  app: litellm
```

So even if the pod changes, the Service still routes traffic to healthy LiteLLM pods.

Internal flow:

```text
Service: ai-gateway-litellm-proxy:4000
  -> Pod 1:4000
  -> Pod 2:4000
```

If you increase replicas, the Service load-balances between pods.

---

## What Is Ingress?

Ingress is a Kubernetes routing rule for HTTP/HTTPS traffic.

It says:

```text
When request comes for this domain,
send it to this Kubernetes Service.
```

Your chart has two Ingress files:

```text
ingress-proxy.yaml
ingress-ui.yaml
```

Example:

```yaml
ingress:
  enabled: true
  className: nginx
  hosts:
    proxy: ai-gateway.example.internal
    ui: ai-gateway-ui.example.internal
```

This means:

```text
ai-gateway.example.internal
  -> ai-gateway-litellm-proxy:4000

ai-gateway-ui.example.internal
  -> ai-gateway-litellm-proxy:4000
```

The `/ui` path is served by the same LiteLLM app.

---

## Ingress Is Not The Proxy Itself

This is important.

Ingress is only the rule.

Something must actually read that rule and proxy traffic.

That "something" is called an Ingress Controller or Gateway.

Common examples:

- NGINX Ingress Controller
- Envoy Gateway
- Istio Ingress Gateway
- Traefik
- HAProxy
- cloud load balancer controllers

Your team said they use **Envoy proxy** to map domains.

That means Envoy is probably the actual reverse proxy that receives traffic and forwards it to your Service.

---

## What Is Envoy?

Envoy is a high-performance reverse proxy.

In simple words:

```text
Client talks to Envoy.
Envoy talks to your Kubernetes Service.
```

Envoy can handle:

- domain routing
- TLS certificates
- path routing
- retries
- timeouts
- headers
- load balancing
- observability

In your setup, Envoy may be the entry point for domains like:

```text
https://ai-gateway.company.internal
```

Then Envoy forwards traffic to:

```text
ai-gateway-litellm-proxy:4000
```

---

## How You Should Integrate With Envoy

Ask the platform/networking team for the required pattern.

There are usually two possibilities.

### Option 1: Envoy Watches Kubernetes Ingress

If Envoy is configured as an Ingress Controller, then your Helm `Ingress` resources are enough.

You only need correct values:

```yaml
ingress:
  enabled: true
  className: envoy
  hosts:
    proxy: ai-gateway.company.internal
    ui: ai-gateway-ui.company.internal
```

Then platform team maps DNS:

```text
ai-gateway.company.internal -> Envoy load balancer
```

Envoy reads the Ingress and forwards to your Service.

### Option 2: Envoy Is Configured Outside Your Chart

Sometimes teams do not let app charts create Ingress.

Instead, they ask for:

```text
service name
namespace
port
health path
domain name
```

You give them:

```text
service name: ai-gateway-litellm-proxy
namespace: ai-gateway or vCluster namespace
port: 4000
health path: /health/liveliness
ui path: /ui
```

Then they configure Envoy route separately.

In this case, set:

```yaml
ingress:
  enabled: false
```

and let Envoy/platform config expose the domain.

---

## What Is vCluster?

vCluster is a virtual Kubernetes cluster running inside a real host Kubernetes cluster.

Think of it like this:

```text
Host Kubernetes Cluster
  |
  +-- vCluster
        |
        +-- your namespace
        +-- your pods
        +-- your services
        +-- your secrets
        +-- your ingress objects
```

You work as if you have your own Kubernetes cluster, but the actual pods run on the host cluster nodes.

That is why pod names in the host cluster can look long:

```text
ai-gateway-litellm-...-x-rmes-x-coe-dev-vcluster
```

Do not manually use those long generated names in Helm values.

Use normal vCluster names:

```text
ai-gateway-litellm
ai-gateway-litellm-proxy
ai-gateway-litellm-secret
```

vCluster handles translation to host cluster names.

---

## Chart Name vs Namespace

Do not mix these two ideas:

| Thing | Example | Meaning |
|---|---|---|
| Chart folder/app/release name | `ai-gateway` | The application name |
| vCluster namespace | `rmes` | The namespace where Kubernetes resources live |

Your chart has this in templates:

```yaml
namespace: {{ .Values.namespace }}
```

So this value is important:

```yaml
namespace: ai-gateway
```

If BuildPiper is deploying the app inside namespace `rmes`, then either:

```yaml
namespace: rmes
```

should be set, or the chart should stop hardcoding `metadata.namespace` and let Helm/BuildPiper namespace control it.

Best simple rule:

```text
The namespace in values.yaml must match the namespace where BuildPiper expects the app resources.
```

The release/app can still be named:

```text
ai-gateway
```

while the namespace is:

```text
rmes
```

That is normal.

---

## How You Access A Pod In vCluster

You normally do not access the pod directly.

Use one of these:

### 1. Service

From inside the cluster:

```text
http://ai-gateway-litellm-proxy:4000
```

### 2. Ingress / Envoy Domain

From browser or another app:

```text
https://ai-gateway.company.internal
```

### 3. Port-forward

Only for debugging from your laptop:

```bash
kubectl port-forward svc/ai-gateway-litellm-proxy -n <namespace> 4000:4000
```

Then:

```text
http://localhost:4000
```

Port-forward is not a production access method.

---

## Do You Need Port-forwarding?

No, not for normal usage.

Use port-forward only when:

- domain is not ready yet
- Ingress/Envoy is not configured yet
- you are debugging locally
- you want to quickly test health from your laptop

For real usage:

```text
Domain -> Envoy/Ingress -> Service -> Pod
```

---

## What To Ask The Envoy/Platform Team

Send this:

```text
Hi team, LiteLLM is deployed in vCluster via BuildPiper.

Please map a domain through Envoy to the Kubernetes Service:

service: ai-gateway-litellm-proxy
port: 4000
health path: /health/liveliness
ui path: /ui

Please confirm whether we should create Kubernetes Ingress in Helm, or whether Envoy routing is managed separately by platform.

If Ingress is required from our chart, please share:
- ingressClassName
- proxy domain
- UI domain, if separate
- TLS/certificate handling approach
```

---

## Current Access Checklist

- [ ] LiteLLM pod is running.
- [ ] Service `ai-gateway-litellm-proxy` exists.
- [ ] Service has endpoint pointing to LiteLLM pod.
- [ ] Ingress exists if your chart manages routing.
- [ ] Envoy route exists if platform manages routing.
- [ ] DNS points domain to Envoy/load balancer.
- [ ] Health check works:

```text
/health/liveliness
```

---

## Simple Troubleshooting

| Symptom | Likely issue | Check |
|---|---|---|
| Pod not running | Secret/config/image issue | `kubectl describe pod ...` |
| Service exists but no traffic | Service selector mismatch | `kubectl get endpoints` |
| Domain not opening | DNS/Envoy/Ingress issue | Ask platform team for route status |
| Port-forward works but domain fails | App is fine; routing is broken | Check Envoy/Ingress |
| Domain opens but `/ui` fails | UI path routing/auth issue | Test `/health/liveliness` first |
| 502/503 from Envoy | Envoy cannot reach Service/pod | Check service, endpoints, health path |

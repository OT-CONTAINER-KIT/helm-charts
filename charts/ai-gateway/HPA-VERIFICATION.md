# LiteLLM HPA Verification Guide

Use this checklist to confirm that Horizontal Pod Autoscaler (HPA) is working correctly for the `ai-gateway-litellm` deployment.

---

## Pre-Checks

Run these commands before applying any load.

### 1. Verify HPA exists and has valid targets

```bash
kubectl get hpa -n ai-gateway
```

**Expected:**
```
NAME                   REFERENCE                       TARGETS         MINPODS   MAXPODS   REPLICAS   AGE
ai-gateway-litellm     Deployment/ai-gateway-litellm   0%/60%, 0%/80%   2         10        2          XXm
```

- `TARGETS` should show actual percentage values (not `<unknown>`).
- If you see `<unknown>`, the HPA cannot read metrics — check the Metrics Server.

### 2. Verify Metrics Server is running

```bash
kubectl top pods -n ai-gateway
```

**Expected:** CPU and memory usage numbers are displayed.

If this fails:
```bash
kubectl get pods -n kube-system | grep metrics-server
```

### 3. Check current pod count

```bash
kubectl get pods -n ai-gateway
```

**Expected:** At least `2` pods running (matches `minReplicas`).

### 4. Verify deployment resource limits (HPA needs these)

```bash
kubectl get deployment ai-gateway-litellm -n ai-gateway -o yaml | grep -A 10 resources
```

**Expected:** Both `requests` and `limits` are set for CPU and memory. HPA requires `requests` to calculate utilization.

---

## Scale-Up Test

### 5. Open a watch terminal

Keep this running in a separate terminal so you can see pods scale in real time:

```bash
kubectl get pods -n ai-gateway -w
```

### 6. Generate artificial CPU load

Exec into one of the running pods and run a CPU burner:

```bash
# Get a pod name
POD=$(kubectl get pod -n ai-gateway -l app=litellm -o jsonpath='{.items[0].metadata.name}')

# Run a CPU stress test inside the pod
kubectl exec -it -n ai-gateway "$POD" -- sh -c 'for i in $(seq 1 4); do python3 -c " import hashlib data = b\"A\" * 1000000 while True: hashlib.sha256(data).hexdigest()" & done echo "CPU load started on 4 cores"'

Alternatively, hit the LiteLLM proxy endpoint with a high volume of requests from your local machine or another pod.

### 7. Watch HPA react

In another terminal:

```bash
kubectl get hpa ai-gateway-litellm -n ai-gateway -w
```

**Expected behavior:**
- CPU target percentage rises above 60%.
- After ~1-2 minutes, `REPLICAS` increases from `2` toward `10`.
- New pods appear in the watch terminal from step 5.

### 8. Verify new pods are healthy

```bash
kubectl get pods -n ai-gateway
```

**Expected:** All new pods show `1/1 Running` and pass readiness probes.

---

## Scale-Down Test

### 9. Stop the load

Kill the CPU stress inside the pod:

```bash
kubectl exec -it -n ai-gateway "$POD" -- sh -c "killall sh || true"
```

Or delete the pod you used to generate load:

```bash
kubectl delete pod "$POD" -n ai-gateway
```

### 10. Watch scale-down

Continue watching:

```bash
kubectl get hpa ai-gateway-litellm -n ai-gateway -w
```

**Expected behavior:**
- CPU target percentage drops back toward 0%.
- After ~5 minutes (default stabilization window), `REPLICAS` scales back down toward `2`.
- Pods terminate gracefully in the watch terminal.

### 11. Verify final state

```bash
kubectl get pods -n ai-gateway
```

**Expected:** Exactly `2` pods remain (matches `minReplicas`).

---

## UI & Service Health Check During Scaling

While pods are scaling up and down, the UI should remain accessible.

### 12. Continuous health check

Run this loop from your local machine or a jump pod:

```bash
while true; do
  curl -s -o /dev/null -w "%{http_code}" https://ai-gateway.opstree.dev/health/readiness
  echo " - $(date)"
  sleep 2
done
```

**Expected:** Returns `200` throughout the entire test. Any `503` or `502` means the Service or Ingress is not handling pod churn gracefully.

### 13. Browser sanity check

Open `https://ai-gateway.opstree.dev/ui` in your browser during peak scale-up.

**Expected:** Page loads without client-side errors. All JS chunks return `200`.

---

## Troubleshooting Common Issues

| Symptom | Likely Cause | Fix |
|---|---|---|
| HPA shows `<unknown>` | Metrics Server missing or broken | Install Metrics Server: `kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml` |
| HPA never scales up | CPU requests not set on containers | Add `resources.requests.cpu` to the deployment spec |
| HPA scales up but UI returns 502/503 | Service selector not matching new pods | Verify `app: litellm` label is consistent on pods and service |
| Pods scale down too fast | `stabilizationWindowSeconds` too short | Add `--horizontal-pod-autoscaler-downscale-stabilization=5m` to kube-controller-manager |
| HPA oscillates (up/down rapidly) | Request target too low or app is bursty | Increase `cpu` target from `60` to `70` or `80` |

---

## Quick Reference Commands

```bash
# View HPA events (why did it scale?)
kubectl describe hpa ai-gateway-litellm -n ai-gateway

# View HPA metrics in real time
kubectl get hpa ai-gateway-litellm -n ai-gateway -w

# Force a manual scale (for testing, not permanent)
kubectl scale deployment ai-gateway-litellm --replicas=5 -n ai-gateway

# Roll back to 2 replicas manually
kubectl scale deployment ai-gateway-litellm --replicas=2 -n ai-gateway

# Check CPU/Memory usage per pod
kubectl top pods -n ai-gateway

# Edit HPA thresholds live
kubectl edit hpa ai-gateway-litellm -n ai-gateway
```






kubectl run -it --rm load-generator \

  --image=alpine/curl \

  -n ai-gateway \

  -- /bin/sh -c "while true; do \

     curl -s -o /dev/null \

     -H 'Authorization: sk-master-ce83d6b7a3b711e35bf3b1f083102169beefb8da33818535fe14fd32e68e84712734c6cc' \

     http://ai-gateway-litellm-proxy/health &\
wait; done"
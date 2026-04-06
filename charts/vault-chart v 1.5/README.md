# Production-Grade HA Vault Cluster with Transit Auto-Unseal

Yeh Helm Chart ek high-availability HashiCorp Vault cluster deploy karta hai jo **Raft Integrated Storage** aur **Transit Auto-Unseal** use karta hai.

---

## ✅ What's Covered (Production Grade Features)
Is chart mein humne yeh saare critical production points cover kiye hain:

1.  **High Availability (HA):** `3-node Raft Quorum` setup transition aur leadership failover ke liye.
2.  **Zero-Involvement Unseal:** `Transit Engine` base auto-unseal, taaki reboot ke baad manual intervention ki zarurat na ho.
3.  **Failover Logic:** `Liveness` aur `Readiness Probes` lagaye hain taaki Kubernetes automatically unhealthy pods ko traffic se hata sake.
4.  **Network Stability:** Ephemeral IPs ki jagah `Headless Service DNS` aur `publishNotReadyAddresses` ka use networking deadlock bachane ke liye.
5.  **Smart Scheduling:** `Pod Anti-Affinity` (preferred) taaki pods alag-alag physical nodes par failover redundancy ke liye spread hon.
6.  **Resource Safety:** `CPU/Memory Requests & Limits` taaki Vault noisy neighbors ya memory leak se protect rahe.
7.  **Storage Flexibility:** `StorageClass` configurable hai (SSD recommended) fast Raft sync ke liye.
8.  **RBAC Security:** Custom `ServiceAccount` aur appropriate `ClusterRole/Binding` permissions.
9.  **Internal Security:** TLS verify skip (`VAULT_SKIP_VERIFY`) internal communication simplified rakhne ke liye (configurable).

---


## 1. Installation

Sabse pehle ek clean namespace banayein aur chart install karein:

```bash
# Namespace create karein
kubectl create namespace vault

# Chart install/upgrade karein
helm upgrade --install vault ./vault-chart -n vault
```

---

## 2. Initial Setup (Sirf Pehli Baar)

Jab aap pehli baar install karenge:
1. **Transit Vault:** Setup apne aap `vault-init-job` ke zariye ho jayega. Yeh ek unseal-key banayega aur use Kubernetes Secret (`vault-transit-token`) mein save kar dega.
2. **Main Vault:** Isse ek baar manually initialize karna hoga (kyunki yeh security best practice hai).

### Step 2.1: Initialize Main Vault
```bash
kubectl exec vault-main-0 -n vault -- vault operator init
```
**IMPORTANT:** Is command ke output mein mile **Root Token** aur **Recovery Keys** ko kahin safe jagah save kar lein.

### Step 2.2: Restart Pods (Auto-Unseal Activate karne ke liye)
Initialization ke baad, pods ko ek baar restart karein taaki wo Transit token utha sakein:
```bash
kubectl delete pod -l app=vault-main -n vault
```
Ab saare pods apne aap **Ready (1/1)** ho jayenge!

---

## 3. Accessing Vault

### Browser Access (UI)
Local machine se access karne ke liye port-forwarding run karein:
```bash
kubectl port-forward svc/vault-main -n vault 8200:8200
```
Ab browser mein open karein: **http://localhost:8200/**

---

## 4. Maintenance Commands

### Check Cluster Status
Dekhne ke liye ki leader kaun hai aur cluster kaisa hai:
```bash
kubectl exec vault-main-0 -n vault -- vault operator raft list-peers
```

### View Logs
Troubleshooting ke liye:
```bash
kubectl logs vault-main-0 -n vault
```

---

## 5. Configuration (values.yaml)

Aap niche di gayi settings ko `values.yaml` mein tweak kar sakte hain:
- `main.replicaCount`: HA ke liye `3` recommended hai.
- `resources`: CPU aur Memory limits assign karne ke liye.
- `persistence.storageClass`: Cloud provider ka SSD storage use karein (e.g., `gp3` on AWS).
- `ingress.enabled`: Load balancer ke zariye bahar access dena ho toh `true` karein.

---

**Happy Secret Managing! 🔐**

# Outline File Storage Migration — Safe Merge Guide

> **Scenario:** Your Outline pods are running in the `docs` namespace. You already have
> user data in the PVC, and you want to merge a `outline-files.tar.gz` from the old
> server **without overwriting** anything that already exists.

---

## What the tar contains

```
public/     → ~2 files (public avatars / shared assets)
uploads/    → ~1,946 files (images, PDFs, attachments — UUID-organised)
avatars/    → ~1 file (user avatar)
```

Outline stores every upload under a UUID path (`uploads/<team-uuid>/<attachment-uuid>/…`).
Because UUIDs are globally unique, **the chance of a filename collision with your
existing PVC data is practically zero**. We will still use a merge strategy that
skips any existing files, just to be 100 % safe.

---

## Step 1 — Back up the current PVC

Always back up before you merge.

```bash
# From a machine that can reach the cluster and the Longhorn UI / kubectl
NAMESPACE=docs
PVC_NAME=outline-outline-pvc
DATE=$(date +%Y%m%d-%H%M%S)

# Create a snapshot or simply tar the live data via a helper pod
kubectl apply -n $NAMESPACE -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: outline-backup
spec:
  containers:
    - name: backup
      image: alpine:3.20
      command: ["sleep", "3600"]
      volumeMounts:
        - name: data
          mountPath: /data
  volumes:
    - name: data
      persistentVolumeClaim:
        claimName: $PVC_NAME
EOF

kubectl wait --for=condition=Ready pod/outline-backup -n $NAMESPACE --timeout=60s

# Stream the current PVC contents into a local tar.gz
kubectl exec -n $NAMESPACE outline-backup -- \
  tar -czf - -C /data . > outline-pvc-backup-${DATE}.tar.gz

kubectl delete pod outline-backup -n $NAMESPACE
```

---

## Step 2 — Scale Outline down to 0 replicas

Stops any writes while we extract.

```bash
kubectl scale deployment outline-outline --replicas=0 -n docs

# Wait until zero pods remain
kubectl wait --for=delete pod -l app=outline -n docs --timeout=120s
```

---

## Step 3 — Deploy the restore helper pod

```bash
kubectl apply -n docs -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: outline-restore
spec:
  containers:
    - name: restore
      image: alpine:3.20
      command: ["sleep", "3600"]
      volumeMounts:
        - name: outline-data
          mountPath: /var/lib/outline/data
  volumes:
    - name: outline-data
      persistentVolumeClaim:
        claimName: outline-outline-pvc
EOF

kubectl wait --for=condition=Ready pod/outline-restore -n docs --timeout=60s
```

---

## Step 4 — Copy the tar into the helper pod

Run this from the machine that holds `outline-files.tar.gz`:

```bash
kubectl cp /home/vishaltyagi/Desktop/outline-files.tar.gz \
  outline-restore:/tmp/outline-files.tar.gz -n docs
```

---

## Step 5 — Merge (safe extract)

We extract with `--keep-old-files` so **existing files are never overwritten**.
New directories (`public/`, `avatars/`) are created; new files inside `uploads/`
are added alongside the existing ones.

```bash
kubectl exec -n docs outline-restore -- sh -c '
  cd /var/lib/outline/data &&
  echo "=== Before merge ===" &&
  du -sh . &&
  echo "Extracting with --keep-old-files (skips any existing paths) ..." &&
  tar --keep-old-files -xzf /tmp/outline-files.tar.gz &&
  echo "=== After merge ===" &&
  du -sh . &&
  echo "=== Top-level dirs ===" &&
  ls -la
'
```

If `tar` reports any "Cannot open: File exists" warnings, those are **expected**
and harmless — they are the files that already lived in your PVC and were skipped.

### Optional: force ownership to match the Outline container

The Outline pod runs as `nodejs` user (`uid 1001`). The Longhorn volume is
`RWX` and currently owned by `root` inside the helper pod. To avoid permission
issues, fix ownership now:

```bash
kubectl exec -n docs outline-restore -- chown -R 1001:1001 /var/lib/outline/data
```

---

## Step 6 — Clean up helper pod

```bash
kubectl delete pod outline-restore -n docs
```

---

## Step 7 — Scale Outline back up

```bash
kubectl scale deployment outline-outline --replicas=2 -n docs

# Wait for rollout
kubectl rollout status deployment/outline-outline -n docs
```

---

## Step 8 — Verify inside a running Outline pod

Pick either pod and check the merged data:

```bash
POD=$(kubectl get pod -n docs -l app=outline -o jsonpath='{.items[0].metadata.name}')

kubectl exec -n docs "$POD" -- ls -la /var/lib/outline/data
kubectl exec -n docs "$POD" -- find /var/lib/outline/data -type f | wc -l
```

You should see `public/`, `uploads/`, and `avatars/` directories, and the total
file count should be **greater** than before the merge.

---

## Full command summary (copy-paste ready)

```bash
#!/bin/bash
set -e

NAMESPACE=docs
PVC_NAME=outline-outline-pvc
TAR_PATH=/home/vishaltyagi/Desktop/outline-files.tar.gz

# 1. Backup (optional but strongly recommended)
kubectl apply -n $NAMESPACE -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: outline-backup
spec:
  containers:
    - name: backup
      image: alpine:3.20
      command: ["sleep", "3600"]
      volumeMounts:
        - name: data
          mountPath: /data
  volumes:
    - name: data
      persistentVolumeClaim:
        claimName: $PVC_NAME
EOF
kubectl wait --for=condition=Ready pod/outline-backup -n $NAMESPACE --timeout=60s
kubectl exec -n $NAMESPACE outline-backup -- tar -czf - -C /data . > outline-pvc-backup-$(date +%Y%m%d-%H%M%S).tar.gz
kubectl delete pod outline-backup -n $NAMESPACE

# 2. Scale down
kubectl scale deployment outline-outline --replicas=0 -n $NAMESPACE
kubectl wait --for=delete pod -l app=outline -n $NAMESPACE --timeout=120s

# 3. Restore helper
kubectl apply -n $NAMESPACE -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: outline-restore
spec:
  containers:
    - name: restore
      image: alpine:3.20
      command: ["sleep", "3600"]
      volumeMounts:
        - name: outline-data
          mountPath: /var/lib/outline/data
  volumes:
    - name: outline-data
      persistentVolumeClaim:
        claimName: $PVC_NAME
EOF
kubectl wait --for=condition=Ready pod/outline-restore -n $NAMESPACE --timeout=60s

# 4. Copy tar
kubectl cp "$TAR_PATH" outline-restore:/tmp/outline-files.tar.gz -n $NAMESPACE

# 5. Merge
kubectl exec -n $NAMESPACE outline-restore -- sh -c \
  'cd /var/lib/outline/data && tar --keep-old-files -xzf /tmp/outline-files.tar.gz'

# 6. Fix ownership
kubectl exec -n $NAMESPACE outline-restore -- chown -R 1001:1001 /var/lib/outline/data

# 7. Clean up helper
kubectl delete pod outline-restore -n $NAMESPACE

# 8. Scale up
kubectl scale deployment outline-outline --replicas=2 -n $NAMESPACE
kubectl rollout status deployment/outline-outline -n $NAMESPACE

echo "Done. Verify with:"
echo "  POD=\$(kubectl get pod -n $NAMESPACE -l app=outline -o jsonpath='{.items[0].metadata.name}')"
echo "  kubectl exec -n $NAMESPACE \"\$POD\" -- find /var/lib/outline/data -type f | wc -l"
```

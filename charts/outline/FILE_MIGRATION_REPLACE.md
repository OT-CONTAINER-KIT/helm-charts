# Outline File Storage Migration — Full Replacement Guide

> **Scenario:** You have replaced the Outline database with a dump from the old
> server. The current PVC still has leftover data from the previous deployment.
> You want to **wipe it clean** and restore the tar from the old server so the
> files match the database exactly.

---

## Quick flow

1. Back up the current PVC (safety net).  
2. Scale Outline down to 0.  
3. Mount the PVC into a helper pod.  
4. **Delete everything** inside `/var/lib/outline/data`.  
5. Extract the tar.  
6. Fix ownership (`uid 1001`).  
7. Scale Outline back up.

---

## Step 1 — Back up the current PVC

Run from your kubectl machine:

```bash
NAMESPACE=docs
DATE=$(date +%Y%m%d-%H%M%S)

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
        claimName: outline-outline-pvc
EOF

kubectl wait --for=condition=Ready pod/outline-backup -n $NAMESPACE --timeout=60s

kubectl exec -n $NAMESPACE outline-backup -- tar -czf - -C /data . \
  > outline-pvc-backup-${DATE}.tar.gz

kubectl delete pod outline-backup -n $NAMESPACE
```

Keep this backup file until you confirm everything works.

---

## Step 2 — Scale Outline down

```bash
kubectl scale deployment outline-outline --replicas=0 -n docs
kubectl wait --for=delete pod -l app=outline -n docs --timeout=120s
```

---

## Step 3 — Deploy the helper pod

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

## Step 4 — Wipe the current data

**This is the clean-slate step.** We delete everything except `lost+found` (which
Longhorn needs).

```bash
kubectl exec -n docs outline-restore -- sh -c '
  cd /var/lib/outline/data &&
  echo "=== Before wipe ===" &&
  du -sh . &&
  ls -la &&
  echo "Wiping everything except lost+found ..." &&
  find . -mindepth 1 -not -name "lost+found" -exec rm -rf {} + 2>/dev/null || true &&
  echo "=== After wipe ===" &&
  ls -la
'
```

---

## Step 5 — Copy and extract the tar

From the machine that holds the tar:

```bash
kubectl cp /home/vishaltyagi/Desktop/outline-files.tar.gz \
  outline-restore:/tmp/outline-files.tar.gz -n docs
```

Extract into the now-empty PVC:

```bash
kubectl exec -n docs outline-restore -- sh -c '
  cd /var/lib/outline/data &&
  tar -xzf /tmp/outline-files.tar.gz &&
  echo "=== Extracted ===" &&
  du -sh . &&
  ls -la
'
```

---

## Step 6 — Fix ownership

Outline runs as user `nodejs` (`uid 1001`):

```bash
kubectl exec -n docs outline-restore -- chown -R 1001:1001 /var/lib/outline/data
```

---

## Step 7 — Clean up helper

```bash
kubectl delete pod outline-restore -n docs
```

---

## Step 8 — Scale Outline back up

```bash
kubectl scale deployment outline-outline --replicas=2 -n docs
kubectl rollout status deployment/outline-outline -n docs
```

---

## Step 9 — Verify

```bash
POD=$(kubectl get pod -n docs -l app=outline -o jsonpath='{.items[0].metadata.name}')

kubectl exec -n docs "$POD" -- ls -la /var/lib/outline/data
kubectl exec -n docs "$POD" -- find /var/lib/outline/data -type f | wc -l
```

You should see `public/`, `uploads/`, and `avatars/` directories, and the file
count should match the old server.

---

## One-shot script

Save as `file-replace.sh` and run it:

```bash
#!/bin/bash
set -euo pipefail

NAMESPACE=docs
PVC_NAME=outline-outline-pvc
TAR_PATH=/home/vishaltyagi/Desktop/outline-files.tar.gz

echo "=== 1. Scale down ==="
kubectl scale deployment outline-outline --replicas=0 -n $NAMESPACE
kubectl wait --for=delete pod -l app=outline -n $NAMESPACE --timeout=120s

echo "=== 2. Deploy helper ==="
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

echo "=== 3. Wipe existing data ==="
kubectl exec -n $NAMESPACE outline-restore -- sh -c \
  'cd /var/lib/outline/data && find . -mindepth 1 -not -name "lost+found" -exec rm -rf {} + 2>/dev/null || true'

echo "=== 4. Copy tar ==="
kubectl cp "$TAR_PATH" outline-restore:/tmp/outline-files.tar.gz -n $NAMESPACE

echo "=== 5. Extract ==="
kubectl exec -n $NAMESPACE outline-restore -- sh -c \
  'cd /var/lib/outline/data && tar -xzf /tmp/outline-files.tar.gz'

echo "=== 6. Fix ownership ==="
kubectl exec -n $NAMESPACE outline-restore -- chown -R 1001:1001 /var/lib/outline/data

echo "=== 7. Clean up ==="
kubectl delete pod outline-restore -n $NAMESPACE

echo "=== 8. Scale up ==="
kubectl scale deployment outline-outline --replicas=2 -n $NAMESPACE
kubectl rollout status deployment/outline-outline -n $NAMESPACE

echo "Done. Verify:"
POD=\$(kubectl get pod -n $NAMESPACE -l app=outline -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n $NAMESPACE "\$POD" -- find /var/lib/outline/data -type f | wc -l
```

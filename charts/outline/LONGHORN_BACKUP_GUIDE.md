# Longhorn Recurring Backup Guide for Outline PVC

> **Scope:** This guide covers how to back up the Outline application PVC using Longhorn’s native RecurringJob feature (snapshots + external backups) — without running any custom backup pod inside the cluster.

---

## 1. How Longhorn Backup Works

Longhorn is a cloud-native, distributed block storage system. Its backup mechanism works in two stages:

### 1.1 Snapshot
A **snapshot** is a point-in-time copy of a volume stored inside the Longhorn cluster. It is fast (copy-on-write) and requires no external storage. Snapshots remain on the same storage nodes.

### 1.2 Backup
A **backup** is an exported snapshot stored in an **external target** (S3 / MinIO / NFS). Backups are deduplicated and compressed by Longhorn, so only changed blocks are sent after the first backup. This is what makes them bandwidth-efficient.

### 1.3 RecurringJob
Longhorn’s `RecurringJob` CRD (or the RecurringJob section in the UI) automates the lifecycle:
- **Task:** `snapshot`, `backup`, or `snapshot-force-create`
- **Schedule:** Standard cron expression
- **Retention:** How many snapshots/backups to keep
- **Volume Selector:** Can select volumes by label or by explicit volume name

When a `backup` task runs, Longhorn will:
1. Create a snapshot of the PVC volume
2. Export that snapshot to your MinIO target
3. Clean up old backups based on retention count

---

## 2. Prerequisites

| Item | Status |
|------|--------|
| Access to the host cluster (not just the vCluster) | Required for Longhorn UI |
| Admin access to Longhorn UI or permission to create `RecurringJob` CRDs | Required |
| MinIO credentials (Access Key + Secret Key) | Required |
| Outline PVC already created and bound | Already done |
| MinIO bucket `docs` already created | Already done |
| MinIO endpoint reachable from Longhorn manager pods (`192.168.8.18:9000`) | Verify this |

### 2.1 Verify Network Reachability

SSH into one of the worker nodes (or any node running Longhorn manager) and run:

```bash
# From a node, test reachability to MinIO
nc -vz 192.168.8.18 9000
# OR
curl -I http://192.168.8.18:9000
```

If this fails, fix network access (firewall rules, VM networking, etc.) before proceeding.

---

## 3. Implementation Steps

### Step 1: Label the PVC (Recommended)

Instead of hardcoding volume names, the best practice is to label the PVC so the RecurringJob can find it dynamically.

```bash
kubectl label pvc <release-name>-outline-pvc \
  longhorn.io/recurring-backup=outline \
  -n <your-namespace>
```

Example:
```bash
kubectl label pvc outline-outline-pvc \
  longhorn.io/recurring-backup=outline \
  -n outline
```

> **Why this matters:** Labels allow the job to automatically attach to the correct volume even if the PVC is recreated or migrated.

### Step 2: Configure the Backup Target in Longhorn

#### Option A: Using Longhorn UI (Recommended for first-time setup)

1. Open the Longhorn UI. The URL depends on your cluster setup:
   - If exposed via Ingress: `https://longhorn.yourcluster.local`
   - If exposed via NodePort: `http://<worker-node-ip>:30001` (replace port with your actual NodePort)
   - If via port-forward: `kubectl port-forward svc/longhorn-frontend 8080:80 -n longhorn-system` then open `http://localhost:8080`

2. Navigate to **Settings → Backup Target**

3. Set the Backup Target URL:
   ```
   s3://docs@minio/192.168.8.18:9000/outline-backups
   ```

4. Configure the **Backup Target Credential Secret**:
   - Create a Kubernetes Secret in the `longhorn-system` namespace:
     ```bash
     kubectl create secret generic minio-backup-creds \
       --from-literal=AWS_ACCESS_KEY_ID='<YOUR_MINIO_ACCESS_KEY>' \
       --from-literal=AWS_SECRET_ACCESS_KEY='<YOUR_MINIO_SECRET_KEY>' \
       --from-literal=AWS_ENDPOINTS='http://192.168.8.18:9000' \
       -n longhorn-system
     ```
   - Enter the secret name `minio-backup-creds` in the UI field.

5. If your MinIO uses a self-signed certificate, also set the **Backupstore Poll Interval** to `300` (seconds) and update the CA bundle if needed.

6. Click **Save**.

#### Option B: Using Longhorn Settings CRD (If UI is not accessible)

Verify or set the backup target via kubectl:

```bash
kubectl get settings.longhorn.io backup-target -n longhorn-system
```

Patch it:
```bash
kubectl patch settings.longhorn.io backup-target \
  --type merge \
  -p '{"value":"s3://docs@minio/192.168.8.18:9000/outline-backups"}' \
  -n longhorn-system
```

Patch the credential secret reference:
```bash
kubectl patch settings.longhorn.io backup-target-credential-secret \
  --type merge \
  -p '{"value":"minio-backup-creds"}' \
  -n longhorn-system
```

### Step 3: Create the RecurringJob

#### Option A: Using the Longhorn UI

1. Go to **RecurringJob → Create RecurringJob**
2. Fill in the form:
   - **Name:** `outline-daily-backup`
   - **Task:** `backup`
   - **Schedule:** `0 2 * * *` (every day at 2 AM)
   - **Retention:** `14` (keeps 14 backups — adjust as needed)
   - **Volume Selector > Labels:** `longhorn.io/recurring-backup=outline`
3. Click **OK**

#### Option B: Using kubectl CRD

Create a file `outline-recurringjob.yaml`:

```yaml
apiVersion: longhorn.io/v1beta2
kind: RecurringJob
metadata:
  name: outline-daily-backup
  namespace: longhorn-system
spec:
  concurrency: 1
  cron: "0 2 * * *"
  groups: []
  labels:
    longhorn.io/recurring-backup: outline
  name: outline-daily-backup
  retain: 14
  task: backup
```

Apply it:
```bash
kubectl apply -f outline-recurringjob.yaml
```

> **Note:** Longhorn will automatically find the volume(s) attached to PVCs with the label `longhorn.io/recurring-backup=outline`.

### Step 4: Verify the Volume Association

Check that Longhorn has linked the job to your volume:

```bash
kubectl get volumes.longhorn.io -n longhorn-system -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.kubernetesStatus.pvcName}{"\t"}{.status.lastBackup}{"\n"}{end}'
```

You should see your volume name and the associated PVC. The `lastBackup` field will populate after the first run.

You can also see the RecurringJob in the Longhorn UI under **Volume** → your volume → **Recurring Jobs** tab.

---

## 4. Monitoring & Alerting

### 4.1 Check Backup Status via Longhorn UI

Open Longhorn → **Volume** → select your volume → **Backup** tab. You will see a list of completed backups with timestamps.

### 4.2 Check Backup Status via kubectl

```bash
kubectl get backups.longhorn.io -n longhorn-system
```

### 4.3 Check RecurringJob Execution History

The Longhorn UI shows the last run status under **RecurringJob** → **outline-daily-backup**.

Or via kubectl:
```bash
kubectl get recurringjobs.longhorn.io outline-daily-backup -n longhorn-system -o yaml | grep -A 20 status
```

### 4.4 Prometheus/Grafana Alerting (Optional but Recommended)

If your cluster has monitoring, alert when:
- `longhorn_volume_snapshot_count` or `longhorn_backup_count` is 0 for a volume that should have daily backups.
- Volume `robustness` becomes `degraded` or `faulted`.

---

## 5. Restoration Guide

If you ever need to restore the PVC from a Longhorn backup, there are two methods.

### 5.1 Restore to a New PVC (Recommended for DR)

1. Go to **Longhorn UI → Volume → Create Volume → Create Disaster Recovery Volume**
2. Or navigate to the **Backup** tab, find the backup from the desired timestamp, and click **Restore**
3. Choose a name for the new volume (e.g., `outline-data-restored`)
4. Once restored, create a PVC from that volume
5. Mount the new PVC into your Outline pod (scale the deployment to 0, swap the PVC, scale back up)

### 5.2 In-Place Volume Restore (Destructive)

If the app is down and the volume is corrupted:
1. Scale the Outline Deployment to 0 replicas
2. In Longhorn UI, select the volume → **Backup** tab → **Restore Latest Backup**
3. Confirm the restore
4. Scale the Deployment back up

> **⚠️ Warning:** In-place restore overwrites the current volume data. Always verify which backup you are restoring.

---

## 6. Production Checklist

| Check | Done? |
|-------|-------|
| MinIO credentials stored in a Kubernetes Secret (`minio-backup-creds`) in `longhorn-system` | [ ] |
| Backup target URL configured in Longhorn settings | [ ] |
| RecurringJob created with task `backup` | [ ] |
| Retention policy set (e.g., 14 backups) | [ ] |
| PVC labeled for job discovery | [ ] |
| Worker nodes can reach `192.168.8.18:9000` | [ ] |
| First manual backup executed successfully and visible in Longhorn UI | [ ] |
| Restore procedure tested in a non-production environment | [ ] |
| Alerts configured for backup failures | [ ] |

---

## 7. Troubleshooting

### Backup target shows “Error” in Longhorn UI

1. Verify network: `kubectl exec -it <longhorn-manager-pod> -n longhorn-system -- nc -vz 192.168.8.18 9000`
2. Verify credentials: `kubectl get secret minio-backup-creds -n longhorn-system -o jsonpath='{.data}'`
3. Verify bucket name: `docs` must already exist.
4. Check Longhorn manager logs: `kubectl logs -n longhorn-system -l app=longhorn-manager --tail=100 | grep -i "backup\|error"`

### Backups are not appearing in the Backup tab

- Ensure the volume is **attached** to a running pod or marked for backup policy. Detached volumes without the correct labels may not trigger backups.
- Make sure the RecurringJob `labels` selector matches the PVC label.

### Backup is very slow on first run

This is normal. The first backup sends all data. Subsequent backups only send changed blocks (deduplication).

---

## 8. Summary of What We’ve Set Up

| Component | Your Setup |
|-----------|------------|
| Storage Engine | Longhorn (via `vcluster-longhorn-restricted-*` StorageClass) |
| Backup Driver | Longhorn RecurringJob |
| External Store | MinIO at `192.168.8.18:9000`, bucket `docs` |
| Backup Path | `outline-backups/` inside the `docs` bucket |
| Schedule | Daily at 02:00 (cron: `0 2 * * *`) |
| Retention | 14 backups |
| Custom Pods in Cluster | **None** — Longhorn manages everything natively |

---

## 9. Quick Reference Commands

```bash
# Label your PVC
kubectl label pvc <release-name>-outline-pvc longhorn.io/recurring-backup=outline -n <namespace>

# Create MinIO creds secret for Longhorn
kubectl create secret generic minio-backup-creds \
  --from-literal=AWS_ACCESS_KEY_ID='<KEY>' \
  --from-literal=AWS_SECRET_ACCESS_KEY='<SECRET>' \
  --from-literal=AWS_ENDPOINTS='http://192.168.8.18:9000' \
  -n longhorn-system

# Apply RecurringJob
kubectl apply -f outline-recurringjob.yaml

# Check backups
kubectl get backups.longhorn.io -n longhorn-system

# Check Longhorn manager logs
kubectl logs -n longhorn-system -l app=longhorn-manager --tail=100
```

---

*Happy backing up.*

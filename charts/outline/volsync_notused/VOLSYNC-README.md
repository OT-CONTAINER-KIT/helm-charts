# VolSync Setup for Outline PVC Backup

This guide explains how to use VolSync to automatically backup your Outline PVC to MinIO.

## 🎯 Why VolSync?

**VolSync** is a Kubernetes operator for asynchronous replication of PersistentVolumes. It's perfect for:

- ✅ **Continuous backups** - Automated on schedule
- ✅ **Point-in-time recovery** - Restore to any backup point
- ✅ **Incremental backups** - Only changed data transferred
- ✅ **Encrypted transfers** - Built-in security
- ✅ **Kubernetes-native** - Uses CRDs and operators
- ✅ **Monitoring** - Metrics and alerts built-in

## 📋 Prerequisites

1. **Kubernetes cluster** with admin access
2. **MinIO** (self-hosted or cloud)
3. **Helm 3** installed
4. **kubectl** configured

## 🚀 Quick Start

### Step 1: Configure the Script

Edit `volsync-setup.sh` and update the configuration:

```bash
# MinIO Configuration
MINIO_ENDPOINT="https://minio.your-domain.com"  # Your MinIO URL
MINIO_BUCKET="outline-backups"                   # Your bucket name
MINIO_ACCESS_KEY="your-access-key"               # Your access key
MINIO_SECRET_KEY="your-secret-key"               # Your secret key

# Backup Schedule (cron format)
BACKUP_SCHEDULE="0 2 * * *"  # Daily at 2 AM

# Retention
RETENTION_DAYS=30  # Keep backups for 30 days
```

### Step 2: Run the Setup Script

```bash
chmod +x volsync-setup.sh
./volsync-setup.sh
```

This will:
1. Install VolSync using Helm
2. Create MinIO secret
3. Create ReplicationSource (for backups)
4. Create ReplicationDestination (for restores)

### Step 3: Verify Installation

```bash
# Check VolSync pods
kubectl get pods -n volsync-system

# Check ReplicationSource
kubectl get replicationsource -n docs

# Check ReplicationDestination
kubectl get replicationdestination -n docs
```

## 📊 Management Commands

Use `volsync-manage.sh` for day-to-day operations:

```bash
chmod +x volsync-manage.sh

# Show status
./volsync-manage.sh status

# Trigger manual backup
./volsync-manage.sh backup

# Trigger manual restore
./volsync-manage.sh restore

# Show logs
./volsync-manage.sh logs

# Show detailed info
./volsync-manage.sh details
```

## 🔄 How It Works

### Backup Flow

```
┌─────────────────────────────────────────────────────────┐
│                    VolSync Backup Flow                  │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────┐      ┌──────────────┐      ┌──────────────┐
│  │  Outline PVC │ ───► │   VolSync    │ ───► │    MinIO     │
│  │  (Source)    │      │  (Operator)  │      │  (Target)    │
│  └──────────────┘      └──────────────┘      └──────────────┘
│                                                         │
│  Schedule: Daily at 2 AM                               │
│  Method: Incremental (restic)                          │
│  Retention: 30 days                                    │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### Restore Flow

```
┌─────────────────────────────────────────────────────────┐
│                   VolSync Restore Flow                  │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────┐      ┌──────────────┐      ┌──────────────┐
│  │    MinIO     │ ───► │   VolSync    │ ───► │  Outline PVC │
│  │  (Source)    │      │  (Operator)  │      │  (Target)    │
│  └──────────────┘      └──────────────┘      └──────────────┘
│                                                         │
│  Options:                                               │
│  - Scheduled restore (daily at 3 AM)                   │
│  - Manual restore (one-time)                           │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

## 📅 Backup Schedule

Default schedule: **Daily at 2 AM**

To change the schedule, edit `volsync-setup.sh`:

```bash
# Every 6 hours
BACKUP_SCHEDULE="0 */6 * * *"

# Every Monday at midnight
BACKUP_SCHEDULE="0 0 * * 1"

# First day of every month
BACKUP_SCHEDULE="0 0 1 * *"
```

## 💾 Retention Policy

Default: **Keep backups for 30 days**

The retention policy is configured in the ReplicationSource:

```yaml
retain:
  daily: 7      # Keep 7 daily backups
  weekly: 4     # Keep 4 weekly backups
  monthly: 6    # Keep 6 monthly backups
  yearly: 1     # Keep 1 yearly backup
```

## 🔐 Security

### MinIO Secret

The MinIO credentials are stored in a Kubernetes Secret:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: minio-secret
  namespace: docs
type: Opaque
stringData:
  RESTORE-source-endpoint: "https://minio.your-domain.com"
  RESTORE-source-bucket: "outline-backups"
  RESTORE-source-access-key: "your-access-key"
  RESTORE-source-secret-key: "your-secret-key"
```

**Best Practices:**
- Use dedicated MinIO credentials for VolSync
- Enable MinIO encryption at rest
- Use TLS for MinIO endpoint
- Rotate credentials regularly

### Encryption at Rest

VolSync supports encryption with restic:

```yaml
restic:
  repository: minio-secret
  encryption: "your-encryption-password"
```

## 📈 Monitoring

### Check Backup Status

```bash
# Describe ReplicationSource
kubectl describe replicationsource outline-outline-pvc-backup -n docs

# Check last sync time
kubectl get replicationsource outline-outline-pvc-backup -n docs -o jsonpath='{.status.lastSyncTime}'
```

### View Logs

```bash
# VolSync operator logs
kubectl logs -n volsync-system -l app.kubernetes.io/name=volsync

# Specific pod logs
kubectl logs -n volsync-system <pod-name>
```

### Metrics

VolSync exposes Prometheus metrics at `:8080/metrics`:

- `volsync_replication_source_sync_total` - Total sync operations
- `volsync_replication_source_sync_duration_seconds` - Sync duration
- `volsync_replication_source_bytes_transferred_total` - Bytes transferred

## 🔄 Manual Operations

### Trigger Manual Backup

```bash
kubectl annotate replicationsource outline-outline-pvc-backup -n docs \
  volsync.backube/manual-next-sync="$(date)"
```

### Trigger Manual Restore

```bash
kubectl annotate replicationdestination outline-outline-pvc-restore-onetime -n docs \
  volsync.backube/manual-restore="$(date)"
```

### View Backup History

```bash
# Check backup snapshots
kubectl exec -n volsync-system <volsync-pod> -- restic snapshots

# List snapshots in MinIO
mc ls outline-minio/outline-backups/restic/ --recursive
```

## 🛠️ Troubleshooting

### Backup Not Running

1. Check VolSync pods:
   ```bash
   kubectl get pods -n volsync-system
   ```

2. Check events:
   ```bash
   kubectl get events -n docs --sort-by='.lastTimestamp' | grep -i volsync
   ```

3. Check ReplicationSource status:
   ```bash
   kubectl describe replicationsource outline-outline-pvc-backup -n docs
   ```

### Restore Failed

1. Check PVC status:
   ```bash
   kubectl get pvc -n docs
   ```

2. Check ReplicationDestination status:
   ```bash
   kubectl describe replicationdestination outline-outline-pvc-restore -n docs
   ```

3. Verify MinIO connectivity:
   ```bash
   kubectl exec -n docs <pod> -- curl -I $MINIO_ENDPOINT
   ```

### Permission Denied

Ensure the MinIO credentials are correct:

```bash
kubectl get secret minio-secret -n docs -o yaml
```

## 📚 Additional Resources

- [VolSync Documentation](https://volsync.readthedocs.io/)
- [VolSync GitHub](https://github.com/backube/volsync)
- [Restic Documentation](https://restic.readthedocs.io/)
- [MinIO Documentation](https://docs.min.io/)

## 🎯 Summary

With VolSync configured, you now have:

1. ✅ **Automated daily backups** to MinIO
2. ✅ **Point-in-time recovery** capability
3. ✅ **Incremental backups** for efficiency
4. ✅ **Encrypted transfers** for security
5. ✅ **Monitoring and alerting** built-in
6. ✅ **Kubernetes-native** management

**Next Steps:**
- Test a manual backup: `./volsync-manage.sh backup`
- Test a restore: `./volsync-manage.sh restore`
- Monitor backups: `./volsync-manage.sh status`
- Set up alerts for backup failures

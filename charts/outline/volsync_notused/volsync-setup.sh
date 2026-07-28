#!/bin/bash

# VolSync Setup for Outline PVC with MinIO
# This script installs and configures VolSync to automatically backup PVC to MinIO

set -e

# ===========================================
# CONFIGURATION
# ===========================================

NAMESPACE="docs"
PVC_NAME="outline-outline-pvc"

# MinIO Configuration
MINIO_ENDPOINT="https://minio.ldc.opstree.dev:9000"  # MinIO API endpoint
MINIO_BUCKET="outline-pvc-backup"                     # Your backup bucket
MINIO_ACCESS_KEY=""  # Paste your access key here
MINIO_SECRET_KEY=""  # Paste your secret key here

# Backup Schedule (cron format)
BACKUP_SCHEDULE="0 2 * * *"  # Daily at 2 AM
# Note: Restore is on-demand only (manual trigger)

# Retention
RETENTION_DAYS=30  # Keep backups for 30 days

# ===========================================
# FUNCTIONS
# ===========================================

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

install_volsync() {
    log "Installing VolSync..."

    # Add Helm repository
    helm repo add backube https://backube.github.io/helm-charts/
    helm repo update

    # Install VolSync
    helm install volsync backube/volsync \
        --namespace volsync-system \
        --create-namespace \
        --set manageCRDs=true \
        --wait

    log "VolSync installed successfully"
}

create_minio_secret() {
    log "Creating MinIO secret..."

    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: minio-secret
  namespace: $NAMESPACE
type: Opaque
stringData:
  RESTORE-source-path: ""
  RESTORE-source-endpoint: "$MINIO_ENDPOINT"
  RESTORE-source-bucket: "$MINIO_BUCKET"
  RESTORE-source-protocol: "https"
  RESTORE-source-access-key: "$MINIO_ACCESS_KEY"
  RESTORE-source-secret-key: "$MINIO_SECRET_KEY"
EOF

    log "MinIO secret created"
}

create_replication_source() {
    log "Creating ReplicationSource for PVC..."

    cat <<EOF | kubectl apply -f -
apiVersion: volsync.backube/v1alpha1
kind: ReplicationSource
metadata:
  name: $PVC_NAME-backup
  namespace: $NAMESPACE
spec:
  sourcePVC: $PVC_NAME
  trigger:
    schedule: "$BACKUP_SCHEDULE"
  restic:
    pruneIntervalDays: 7
    repository: minio-secret
    retain:
      daily: 7
      weekly: 4
      monthly: 6
      yearly: 1
    copyMethod: Direct
EOF

    log "ReplicationSource created"
}

create_replication_destination_onetime() {
    log "Creating one-time ReplicationDestination for immediate restore..."

    cat <<EOF | kubectl apply -f -
apiVersion: volsync.backube/v1alpha1
kind: ReplicationDestination
metadata:
  name: $PVC_NAME-restore-onetime
  namespace: $NAMESPACE
spec:
  trigger:
    manual: restore-now
  restic:
    repository: minio-secret
    copyMethod: Direct
    destinationPVC: $PVC_NAME
EOF

    log "One-time ReplicationDestination created"
}

verify_installation() {
    log "Verifying VolSync installation..."

    # Check VolSync pods
    kubectl get pods -n volsync-system

    # Check ReplicationSource
    kubectl get replicationsource -n $NAMESPACE

    # Check ReplicationDestination
    kubectl get replicationdestination -n $NAMESPACE

    log "Verification complete"
}

print_instructions() {
    echo "=========================================="
    echo "✅ VolSync Setup Complete!"
    echo "=========================================="
    echo ""
    echo "📋 Next Steps:"
    echo ""
    echo "1. Verify installation:"
    echo "   kubectl get pods -n volsync-system"
    echo "   kubectl get replicationsource -n $NAMESPACE"
    echo ""
    echo "2. Check backup status:"
    echo "   kubectl describe replicationsource $PVC_NAME-backup -n $NAMESPACE"
    echo ""
    echo "3. Trigger manual backup:"
    echo "   kubectl annotate replicationsource $PVC_NAME-backup -n $NAMESPACE \\"
    echo "     volsync.backube/manual-next-sync=\"$(date)\""
    echo ""
    echo "4. Trigger manual restore:"
    echo "   kubectl annotate replicationdestination $PVC_NAME-restore-onetime -n $NAMESPACE \\"
    echo "     volsync.backube/manual-restore=\"$(date)\""
    echo ""
    echo "5. View backup logs:"
    echo "   kubectl logs -n volsync-system -l app.kubernetes.io/name=volsync"
    echo ""
    echo "📊 Backup Schedule: $BACKUP_SCHEDULE"
    echo "🔄 Restore Schedule: $RESTORE_SCHEDULE"
    echo "💾 Retention: $RETENTION_DAYS days"
    echo ""
    echo "=========================================="
}

# ===========================================
# MAIN EXECUTION
# ===========================================

echo "=========================================="
echo "VolSync Setup for Outline PVC"
echo "=========================================="
echo "Namespace: $NAMESPACE"
echo "PVC: $PVC_NAME"
echo "MinIO: $MINIO_ENDPOINT"
echo "Bucket: $MINIO_BUCKET"
echo "=========================================="

install_volsync
create_minio_secret
create_replication_source
create_replication_destination_onetime
verify_installation
print_instructions

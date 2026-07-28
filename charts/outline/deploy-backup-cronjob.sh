#!/bin/bash

# Deploy Outline Backup CronJob
# This script creates the CronJob to backup PVC to MinIO

set -e

# ===========================================
# CONFIGURATION - UPDATE THESE
# ===========================================

NAMESPACE="docs"
MINIO_ACCESS_KEY="UZ86MT0IVFGNP8QDXWBK"  # Paste your access key here
MINIO_SECRET_KEY="N71EsHvz1MAy32UMNEMPiAEa+jAoa0qu7TryycwE"  # Paste your secret key here

# ===========================================
# FUNCTIONS
# ===========================================

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

check_prerequisites() {
    log "Checking prerequisites..."

    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        echo "Error: kubectl not found"
        exit 1
    fi

    # Check access keys
    if [ -z "$MINIO_ACCESS_KEY" ] || [ -z "$MINIO_SECRET_KEY" ]; then
        echo "Error: Please provide MINIO_ACCESS_KEY and MINIO_SECRET_KEY"
        echo "Edit this script and add your credentials"
        exit 1
    fi

    # Test MinIO access key permissions
    log "Testing MinIO access key permissions..."
    mc alias set test-perm https://minio.ldc.opstree.dev:9000 "$MINIO_ACCESS_KEY" "$MINIO_SECRET_KEY" --api S3v4 2>/dev/null

    if echo "test" | mc pipe test-perm/outline-pvc-backup/.permission-test 2>/dev/null; then
        mc rm test-perm/outline-pvc-backup/.permission-test 2>/dev/null
        log "✅ Access key has write permissions"
    else
        echo ""
        echo "❌ ERROR: Access key doesn't have write permission!"
        echo ""
        echo "Fix this first by running:"
        echo "  mc admin policy attach outline-minio readwrite --user $MINIO_ACCESS_KEY"
        echo ""
        exit 1
    fi

    log "Prerequisites check passed"
}

update_secret() {
    log "Updating MinIO secret..."

    # Delete existing secret if it exists
    kubectl delete secret minio-backup-secret -n $NAMESPACE --ignore-not-found

    # Create new secret with credentials
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: minio-backup-secret
  namespace: $NAMESPACE
type: Opaque
stringData:
  access-key: "$MINIO_ACCESS_KEY"
  secret-key: "$MINIO_SECRET_KEY"
EOF

    log "MinIO secret created"
}

deploy_cronjob() {
    log "Deploying backup CronJob..."

    # Apply the CronJob
    kubectl apply -f outline-backup-cronjob.yaml

    log "CronJob deployed"
}

verify_deployment() {
    log "Verifying deployment..."

    # Check CronJob
    kubectl get cronjob -n $NAMESPACE

    # Check secret
    kubectl get secret minio-backup-secret -n $NAMESPACE

    # Check ConfigMap
    kubectl get configmap outline-backup-script -n $NAMESPACE

    log "Verification complete"
}

trigger_first_backup() {
    log "Triggering first backup..."

    # Create a one-time job for immediate backup
    kubectl create job outline-backup-manual-$(date +%s) \
        --from=cronjob/outline-backup \
        -n $NAMESPACE

    log "First backup triggered. Check logs with:"
    echo "  kubectl logs -n $NAMESPACE -l app=outline-backup --tail=100 -f"
}

print_instructions() {
    echo "=========================================="
    echo "✅ Backup CronJob Deployed!"
    echo "=========================================="
    echo ""
    echo "📋 What was created:"
    echo "  1. Secret: minio-backup-secret (MinIO credentials)"
    echo "  2. ConfigMap: outline-backup-script (backup script)"
    echo "  3. CronJob: outline-backup (daily at 2 AM)"
    echo ""
    echo "📊 Backup Schedule: Daily at 2 AM"
    echo "💾 Retention: 7 days"
    echo "📦 Bucket: outline-pvc-backup"
    echo ""
    echo "🔧 Useful Commands:"
    echo ""
    echo "  # Check CronJob status:"
    echo "  kubectl get cronjob -n $NAMESPACE"
    echo ""
    echo "  # Check recent jobs:"
    echo "  kubectl get jobs -n $NAMESPACE --sort-by=.metadata.creationTimestamp"
    echo ""
    echo "  # View backup logs:"
    echo "  kubectl logs -n $NAMESPACE -l app=outline-backup --tail=100 -f"
    echo ""
    echo "  # Trigger manual backup:"
    echo "  kubectl create job outline-backup-manual-\\\$(date +%s) \\"
    echo "    --from=cronjob/outline-backup -n $NAMESPACE"
    echo ""
    echo "  # List backups in MinIO:"
    echo "  mc ls outline-minio/outline-pvc-backup/"
    echo ""
    echo "=========================================="
}

# ===========================================
# MAIN EXECUTION
# ===========================================

echo "=========================================="
echo "Deploy Outline Backup CronJob"
echo "=========================================="
echo ""
echo "This will create a daily backup of your Outline PVC"
echo "and push it to MinIO bucket: outline-pvc-backup"
echo ""
echo "=========================================="

check_prerequisites
update_secret
deploy_cronjob
verify_deployment

echo ""
echo "Do you want to trigger the first backup now? (y/n)"
read -r TRIGGER_BACKUP

if [ "$TRIGGER_BACKUP" = "y" ] || [ "$TRIGGER_BACKUP" = "Y" ]; then
    trigger_first_backup
fi

print_instructions

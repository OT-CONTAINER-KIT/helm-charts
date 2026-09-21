#!/bin/bash
#
# Outline PVC disaster recovery — guided restore from a MinIO backup.
#
# Usage:
#   ./restore.sh daily/outline_20260921_093248.tar.gz
#   ./restore.sh monthly/outline_20260921_094838.tar.gz
#
# What it does:
#   1. Scales outline-outline to 0 (stops writers).
#   2. Re-applies pvc.yaml; if the PVC stays Pending because the old PV is
#      Released (reclaimPolicy: Retain), it finds that PV and — after your
#      confirmation — clears its claimRef so the PVC rebinds to it.
#   3. Renders restore-job.yaml with your BACKUP_KEY, applies it, waits.
#   4. Prints the Job log tail (file count) for your verification.
#   5. Scales outline-outline back to 2 and waits for rollout.
#
# Read README.md first. This script is the README, automated.

set -e

NAMESPACE="docs"
DEPLOYMENT="outline-outline"
PVC_NAME="outline-outline-pvc"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ -z "$1" ]; then
    echo "Usage: $0 <BACKUP_KEY, e.g. daily/outline_20260921_093248.tar.gz>"
    echo ""
    echo "List available backups with:"
    echo "  mc ls --recursive minio-backup/outline-pvc-backup/"
    exit 1
fi
BACKUP_KEY="$1"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

log "=== 1. Scaling $DEPLOYMENT to 0 ==="
kubectl scale deployment "$DEPLOYMENT" --replicas=0 -n "$NAMESPACE"
kubectl wait --for=delete pod -l app=outline -n "$NAMESPACE" --timeout=180s || true

log "=== 2. Re-creating PVC ==="
kubectl apply -f "$SCRIPT_DIR/pvc.yaml"

log "Waiting for PVC to bind (up to 3 min)..."
if ! kubectl wait --for=jsonpath='{.status.phase}'=Bound "pvc/$PVC_NAME" -n "$NAMESPACE" --timeout=180s 2>/dev/null; then
    log "PVC is not Bound. Looking for a Released PV from the old claim (Retain policy)..."
    PV=$(kubectl get pv -o jsonpath='{range .items[?(@.status.phase=="Released")]}{.metadata.name}{" "}{.spec.claimRef.namespace}/{.spec.claimRef.name}{"\n"}{end}' | awk -v want="$NAMESPACE/$PVC_NAME" '$2==want {print $1}' | head -n 1)
    if [ -z "$PV" ]; then
        log "No Released PV found for $NAMESPACE/$PVC_NAME. The volume may be gone;"
        log "a fresh empty volume will be provisioned — restore will fill it from MinIO."
    else
        log "Found Released PV: $PV (data preserved by Retain policy)."
        echo "Clear its claimRef so pvc/$PVC_NAME rebinds to it? (y/n)"
        read -r ANSWER
        if [ "$ANSWER" = "y" ] || [ "$ANSWER" = "Y" ]; then
            kubectl patch pv "$PV" --type=json -p='[{"op":"remove","path":"/spec/claimRef"}]'
            kubectl wait --for=jsonpath='{.status.phase}'=Bound "pvc/$PVC_NAME" -n "$NAMESPACE" --timeout=180s
            log "PVC rebound to $PV."
        else
            log "Skipped. Fix the PV manually, then re-run this script."
            exit 1
        fi
    fi
fi
kubectl get pvc "$PVC_NAME" -n "$NAMESPACE"

log "=== 3. Running restore Job for $BACKUP_KEY ==="
kubectl delete job outline-restore -n "$NAMESPACE" --ignore-not-found
sed "s|REPLACE_ME_e.g_daily/outline_20260921_093248.tar.gz|$BACKUP_KEY|" \
    "$SCRIPT_DIR/restore-job.yaml" | kubectl apply -f -
kubectl wait --for=condition=complete job/outline-restore -n "$NAMESPACE" --timeout=1800s

log "=== 4. Restore Job logs (verify file count) ==="
kubectl logs -n "$NAMESPACE" -l app=outline-restore --tail=25

log "=== 5. Scaling $DEPLOYMENT back to 2 ==="
kubectl scale deployment "$DEPLOYMENT" --replicas=2 -n "$NAMESPACE"
kubectl rollout status "deployment/$DEPLOYMENT" -n "$NAMESPACE"

log "Done. Spot-check inside a running pod:"
POD=$(kubectl get pod -n "$NAMESPACE" -l app=outline -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n "$NAMESPACE" "$POD" -- find /var/lib/outline/data -type f | wc -l

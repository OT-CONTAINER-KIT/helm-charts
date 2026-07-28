#!/bin/bash

# VolSync Management Script
# Manage backups, restores, and monitoring for Outline PVC

set -e

# Configuration
NAMESPACE="docs"
PVC_NAME="outline-outline-pvc"

# ===========================================
# FUNCTIONS
# ===========================================

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

show_status() {
    echo "=========================================="
    echo "VolSync Status"
    echo "=========================================="
    echo ""

    echo "📦 VolSync Pods:"
    kubectl get pods -n volsync-system -o wide
    echo ""

    echo "🔄 ReplicationSource:"
    kubectl get replicationsource -n $NAMESPACE -o wide
    echo ""

    echo "📥 ReplicationDestination:"
    kubectl get replicationdestination -n $NAMESPACE -o wide
    echo ""

    echo "📊 Recent Events:"
    kubectl get events -n $NAMESPACE --sort-by='.lastTimestamp' | grep -i volsync | tail -10
    echo ""
}

trigger_backup() {
    log "Triggering manual backup..."

    kubectl annotate replicationsource $PVC_NAME-backup -n $NAMESPACE \
        volsync.backube/manual-next-sync="$(date)" \
        --overwrite

    log "Manual backup triggered. Check status with:"
    echo "  kubectl describe replicationsource $PVC_NAME-backup -n $NAMESPACE"
}

trigger_restore() {
    log "Triggering manual restore..."

    kubectl annotate replicationdestination $PVC_NAME-restore-onetime -n $NAMESPACE \
        volsync.backube/manual-restore="$(date)" \
        --overwrite

    log "Manual restore triggered. Check status with:"
    echo "  kubectl describe replicationdestination $PVC_NAME-restore-onetime -n $NAMESPACE"
}

show_backup_logs() {
    log "Showing VolSync logs..."

    kubectl logs -n volsync-system -l app.kubernetes.io/name=volsync --tail=100 -f
}

show_replication_details() {
    echo "=========================================="
    echo "ReplicationSource Details"
    echo "=========================================="
    kubectl describe replicationsource $PVC_NAME-backup -n $NAMESPACE
    echo ""

    echo "=========================================="
    echo "ReplicationDestination Details"
    echo "=========================================="
    kubectl describe replicationdestination $PVC_NAME-restore -n $NAMESPACE
}

list_backups() {
    log "Listing backups in MinIO..."

    # This requires mc to be configured
    if command -v mc &> /dev/null; then
        mc ls outline-minio/outline-pvc-backup/ --recursive | grep "restic"
    else
        echo "MinIO Client (mc) not found. Please install it first."
        echo "Or check backups directly in MinIO UI."
    fi
}

show_help() {
    echo "=========================================="
    echo "VolSync Management Commands"
    echo "=========================================="
    echo ""
    echo "Usage: $0 <command>"
    echo ""
    echo "Commands:"
    echo "  status          Show VolSync status"
    echo "  backup          Trigger manual backup"
    echo "  restore         Trigger manual restore"
    echo "  logs            Show VolSync logs"
    echo "  details         Show detailed replication info"
    echo "  list-backups    List backups in MinIO"
    echo "  help            Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 status"
    echo "  $0 backup"
    echo "  $0 restore"
    echo ""
    echo "=========================================="
}

# ===========================================
# MAIN EXECUTION
# ===========================================

case "${1:-help}" in
    status)
        show_status
        ;;
    backup)
        trigger_backup
        ;;
    restore)
        trigger_restore
        ;;
    logs)
        show_backup_logs
        ;;
    details)
        show_replication_details
        ;;
    list-backups)
        list_backups
        ;;
    help|*)
        show_help
        ;;
esac

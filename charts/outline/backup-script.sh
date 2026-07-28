#!/bin/bash

# Outline PVC Backup Script
# Runs inside the CronJob pod to backup PVC and push to MinIO

set -e

# ===========================================
# CONFIGURATION
# ===========================================

BACKUP_DIR="/backup"
PVC_MOUNT="/outline-data"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILENAME="outline_${TIMESTAMP}.tar.gz"
RETENTION_DAYS=7

# MinIO Configuration (from environment variables)
MINIO_ENDPOINT="${MINIO_ENDPOINT}"
MINIO_ACCESS_KEY="${MINIO_ACCESS_KEY}"
MINIO_SECRET_KEY="${MINIO_SECRET_KEY}"
MINIO_BUCKET="${MINIO_BUCKET}"

# ===========================================
# FUNCTIONS
# ===========================================

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

setup_mc() {
    log "Setting up MinIO Client..."

    # Configure mc alias
    mc alias set minio-backup $MINIO_ENDPOINT $MINIO_ACCESS_KEY $MINIO_SECRET_KEY --api S3v4

    log "MinIO Client configured"
}

create_backup() {
    log "Creating backup: $BACKUP_FILENAME"

    # Create backup directory
    mkdir -p $BACKUP_DIR

    # Create tar.gz of PVC data
    tar -czf $BACKUP_DIR/$BACKUP_FILENAME -C $PVC_MOUNT .

    # Get backup size
    BACKUP_SIZE=$(du -h $BACKUP_DIR/$BACKUP_FILENAME | cut -f1)
    log "Backup created: $BACKUP_FILENAME ($BACKUP_SIZE)"
}

upload_to_minio() {
    log "Uploading to MinIO..."

    # Upload backup
    mc cp $BACKUP_DIR/$BACKUP_FILENAME minio-backup/$MINIO_BUCKET/$BACKUP_FILENAME

    log "Uploaded to: $MINIO_ENDPOINT/$MINIO_BUCKET/$BACKUP_FILENAME"
}

cleanup_old_backups() {
    log "Cleaning up backups older than $RETENTION_DAYS days..."

    # List all backups and filter by age
    mc ls minio-backup/$MINIO_BUCKET/outline_*.tar.gz --json | \
        while read -r line; do
            # Extract filename and date
            filename=$(echo "$line" | jq -r '.key')
            last_modified=$(echo "$line" | jq -r '.lastModified')

            # Calculate age in days
            backup_date=$(date -d "$last_modified" +%s)
            current_date=$(date +%s)
            age_days=$(( (current_date - backup_date) / 86400 ))

            # Delete if older than retention period
            if [ $age_days -gt $RETENTION_DAYS ]; then
                log "Deleting old backup: $filename ($age_days days old)"
                mc rm minio-backup/$MINIO_BUCKET/$filename
            fi
        done

    log "Cleanup completed"
}

cleanup_local() {
    log "Cleaning up local backup files..."
    rm -f $BACKUP_DIR/$BACKUP_FILENAME
    log "Local cleanup completed"
}

# ===========================================
# MAIN EXECUTION
# ===========================================

echo "=========================================="
echo "Outline PVC Backup"
echo "=========================================="
log "Starting backup process..."

setup_mc
create_backup
upload_to_minio
cleanup_old_backups
cleanup_local

log "=========================================="
log "✅ Backup completed successfully!"
log "=========================================="

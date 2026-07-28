#!/bin/bash

# Outline PVC Advanced Backup Script
# Supports both MinIO and S3 with encryption and retention policies

set -e

# ===========================================
# CONFIGURATION
# ===========================================

# Kubernetes Configuration
NAMESPACE="docs"
PVC_NAME="outline-outline-pvc"

# Backup Configuration
BACKUP_DIR="/tmp/outline-backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILENAME="outline_${TIMESTAMP}.tar.gz"

# Storage Configuration (choose one: "minio" or "s3")
STORAGE_TYPE="minio"

# MinIO Configuration (if STORAGE_TYPE="minio")
MINIO_ENDPOINT="https://minio.your-domain.com"
MINIO_BUCKET="outline-backups"
MINIO_ACCESS_KEY="your-access-key"
MINIO_SECRET_KEY="your-secret-key"

# S3 Configuration (if STORAGE_TYPE="s3")
AWS_REGION="us-east-1"
S3_BUCKET="your-outline-backups"

# Optional: Encryption (set to "true" to enable)
ENABLE_ENCRYPTION=false
ENCRYPTION_PASSPHRASE="your-strong-passphrase"

# Optional: Retention (number of backups to keep)
RETENTION_COUNT=10

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

    # Check storage client
    if [ "$STORAGE_TYPE" = "minio" ]; then
        if ! command -v mc &> /dev/null; then
            log "Installing MinIO Client (mc)..."
            curl -o /tmp/mc https://dl.min.io/client/mc/release/linux-amd64/mc
            chmod +x /tmp/mc
            sudo mv /tmp/mc /usr/local/bin/mc
        fi
    elif [ "$STORAGE_TYPE" = "s3" ]; then
        if ! command -v aws &> /dev/null; then
            echo "Error: AWS CLI not found"
            echo "Install with: pip install awscli"
            exit 1
        fi
        if ! aws sts get-caller-identity &> /dev/null; then
            echo "Error: AWS CLI not configured"
            echo "Run: aws configure"
            exit 1
        fi
    fi

    log "Prerequisites check passed"
}

backup_pvc() {
    log "Starting PVC backup..."

    # Create backup directory
    mkdir -p $BACKUP_DIR

    # Create backup pod
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: outline-backup-pod
  namespace: $NAMESPACE
  labels:
    app: outline-backup
    purpose: backup
spec:
  containers:
  - name: backup
    image: alpine:latest
    command: ["sleep", "3600"]
    volumeMounts:
    - name: outline-data
      mountPath: /outline-data
    - name: backup-storage
      mountPath: /backup
  volumes:
  - name: outline-data
    persistentVolumeClaim:
      claimName: $PVC_NAME
  - name: backup-storage
    emptyDir: {}
  restartPolicy: Never
EOF

    # Wait for pod to be ready
    log "Waiting for backup pod..."
    kubectl wait --for=condition=Ready pod/outline-backup-pod -n $NAMESPACE --timeout=120s

    # Create backup
    log "Creating tar.gz backup..."
    kubectl exec -n $NAMESPACE outline-backup-pod -- tar -czf /backup/$BACKUP_FILENAME -C /outline-data .

    # Download backup
    log "Downloading backup..."
    kubectl cp $NAMESPACE/outline-backup-pod:/backup/$BACKUP_FILENAME $BACKUP_DIR/$BACKUP_FILENAME

    # Cleanup pod
    log "Cleaning up backup pod..."
    kubectl delete pod outline-backup-pod -n $NAMESPACE

    log "Backup created: $BACKUP_DIR/$BACKUP_FILENAME"
}

encrypt_backup() {
    if [ "$ENABLE_ENCRYPTION" = true ]; then
        log "Encrypting backup..."
        openssl enc -aes-256-cbc -salt -pbkdf2 -in $BACKUP_DIR/$BACKUP_FILENAME -out $BACKUP_DIR/$BACKUP_FILENAME.enc -pass pass:$ENCRYPTION_PASSPHRASE
        rm -f $BACKUP_DIR/$BACKUP_FILENAME
        BACKUP_FILENAME="${BACKUP_FILENAME}.enc"
        log "Backup encrypted: $BACKUP_FILENAME"
    fi
}

upload_to_minio() {
    log "Uploading to MinIO..."

    # Configure mc alias
    mc alias set outline-minio $MINIO_ENDPOINT $MINIO_ACCESS_KEY $MINIO_SECRET_KEY

    # Create bucket if needed
    mc mb outline-minio/$MINIO_BUCKET --ignore-existing

    # Upload
    mc cp $BACKUP_DIR/$BACKUP_FILENAME outline-minio/$MINIO_BUCKET/$BACKUP_FILENAME

    log "Uploaded to: $MINIO_ENDPOINT/$MINIO_BUCKET/$BACKUP_FILENAME"
}

upload_to_s3() {
    log "Uploading to AWS S3..."

    # Create bucket if needed
    aws s3 mb s3://$S3_BUCKET --region $AWS_REGION 2>/dev/null || true

    # Upload
    aws s3 cp $BACKUP_DIR/$BACKUP_FILENAME s3://$S3_BUCKET/$BACKUP_FILENAME --region $AWS_REGION

    log "Uploaded to: s3://$S3_BUCKET/$BACKUP_FILENAME"
}

cleanup_old_backups() {
    if [ $RETENTION_COUNT -gt 0 ]; then
        log "Cleaning up old backups (keeping last $RETENTION_COUNT)..."

        if [ "$STORAGE_TYPE" = "minio" ]; then
            # List backups sorted by date, remove old ones
            mc ls outline-minio/$MINIO_BUCKET/outline_*.tar.gz* | \
                sort -k9 -r | \
                tail -n +$((RETENTION_COUNT + 1)) | \
                awk '{print $NF}' | \
                xargs -I {} mc rm outline-minio/$MINIO_BUCKET/{}
        elif [ "$STORAGE_TYPE" = "s3" ]; then
            # List backups sorted by date, remove old ones
            aws s3 ls s3://$S3_BUCKET/outline_*.tar.gz* | \
                sort -k4 -r | \
                tail -n +$((RETENTION_COUNT + 1)) | \
                awk '{print $4}' | \
                xargs -I {} aws s3 rm s3://$S3_BUCKET/{}
        fi

        log "Old backups cleaned up"
    fi
}

cleanup_local() {
    log "Cleaning up local files..."
    rm -f $BACKUP_DIR/$BACKUP_FILENAME
    log "Local cleanup completed"
}

# ===========================================
# MAIN EXECUTION
# ===========================================

echo "=========================================="
echo "Outline PVC Advanced Backup"
echo "=========================================="
echo "Namespace: $NAMESPACE"
echo "PVC: $PVC_NAME"
echo "Storage: $STORAGE_TYPE"
echo "Encryption: $ENABLE_ENCRYPTION"
echo "Retention: $RETENTION_COUNT backups"
echo "=========================================="

check_prerequisites
backup_pvc
encrypt_backup

if [ "$STORAGE_TYPE" = "minio" ]; then
    upload_to_minio
elif [ "$STORAGE_TYPE" = "s3" ]; then
    upload_to_s3
else
    echo "Error: Invalid STORAGE_TYPE. Use 'minio' or 's3'"
    exit 1
fi

cleanup_old_backups
cleanup_local

echo "=========================================="
echo "✅ Backup completed successfully!"
echo "=========================================="

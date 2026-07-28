#!/bin/bash

# Outline PVC Backup Script - Upload to MinIO
# This script creates a backup of the Outline PVC and uploads it to MinIO

set -e

# Configuration
NAMESPACE="docs"
PVC_NAME="outline-outline-pvc"
BACKUP_DIR="/tmp/outline-backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILENAME="outline_${TIMESTAMP}.tar.gz"

# MinIO Configuration
MINIO_ENDPOINT="https://minio.your-domain.com"  # Change this to your MinIO endpoint
MINIO_BUCKET="outline-backups"  # Change this to your bucket name
MINIO_ACCESS_KEY="your-access-key"  # Change this to your MinIO access key
MINIO_SECRET_KEY="your-secret-key"  # Change this to your MinIO secret key

echo "=========================================="
echo "Outline PVC Backup to MinIO"
echo "=========================================="
echo "Namespace: $NAMESPACE"
echo "PVC Name: $PVC_NAME"
echo "Backup File: $BACKUP_FILENAME"
echo "MinIO Endpoint: $MINIO_ENDPOINT"
echo "MinIO Bucket: $MINIO_BUCKET"
echo "=========================================="

# Create backup directory if it doesn't exist
mkdir -p $BACKUP_DIR

# Create a temporary pod to backup the PVC
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: outline-backup-pod
  namespace: $NAMESPACE
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

echo "Waiting for backup pod to be ready..."
kubectl wait --for=condition=Ready pod/outline-backup-pod -n $NAMESPACE --timeout=120s

echo "Creating backup..."
kubectl exec -n $NAMESPACE outline-backup-pod -- tar -czf /backup/$BACKUP_FILENAME -C /outline-data .

echo "Downloading backup to local machine..."
kubectl cp $NAMESPACE/outline-backup-pod:/backup/$BACKUP_FILENAME $BACKUP_DIR/$BACKUP_FILENAME

echo "Cleaning up backup pod..."
kubectl delete pod outline-backup-pod -n $NAMESPACE

echo "Backup created: $BACKUP_DIR/$BACKUP_FILENAME"

# Upload to MinIO using mc (MinIO Client)
echo "Uploading to MinIO..."

# Check if mc is installed
if ! command -v mc &> /dev/null; then
    echo "MinIO Client (mc) not found. Installing..."
    curl -o /tmp/mc https://dl.min.io/client/mc/release/linux-amd64/mc
    chmod +x /tmp/mc
    sudo mv /tmp/mc /usr/local/bin/mc
fi

# Configure mc alias
mc alias set outline-minio $MINIO_ENDPOINT $MINIO_ACCESS_KEY $MINIO_SECRET_KEY

# Create bucket if it doesn't exist
mc mb outline-minio/$MINIO_BUCKET --ignore-existing

# Upload the backup
mc cp $BACKUP_DIR/$BACKUP_FILENAME outline-minio/$MINIO_BUCKET/$BACKUP_FILENAME

echo "=========================================="
echo "Backup completed successfully!"
echo "File: $BACKUP_FILENAME"
echo "Location: $MINIO_ENDPOINT/$MINIO_BUCKET/$BACKUP_FILENAME"
echo "=========================================="

# Cleanup local backup file
rm -f $BACKUP_DIR/$BACKUP_FILENAME
echo "Local backup file cleaned up."

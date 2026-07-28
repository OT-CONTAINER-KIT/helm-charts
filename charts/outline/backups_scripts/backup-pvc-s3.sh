#!/bin/bash

# Outline PVC Backup Script - Upload to AWS S3
# This script creates a backup of the Outline PVC and uploads it to AWS S3

set -e

# Configuration
NAMESPACE="docs"
PVC_NAME="outline-outline-pvc"
BACKUP_DIR="/tmp/outline-backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILENAME="outline_${TIMESTAMP}.tar.gz"

# AWS S3 Configuration
AWS_REGION="us-east-1"  # Change this to your region
S3_BUCKET="your-outline-backups"  # Change this to your S3 bucket name

echo "=========================================="
echo "Outline PVC Backup to AWS S3"
echo "=========================================="
echo "Namespace: $NAMESPACE"
echo "PVC Name: $PVC_NAME"
echo "Backup File: $BACKUP_FILENAME"
echo "AWS Region: $AWS_REGION"
echo "S3 Bucket: $S3_BUCKET"
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

# Upload to AWS S3 using aws cli
echo "Uploading to AWS S3..."

# Check if aws cli is installed
if ! command -v aws &> /dev/null; then
    echo "AWS CLI not found. Please install it first:"
    echo "  pip install awscli"
    echo "  or"
    echo "  curl 'https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip' -o 'awscliv2.zip'"
    echo "  unzip awscliv2.zip && sudo ./aws/install"
    exit 1
fi

# Check if AWS is configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo "AWS CLI not configured. Please run: aws configure"
    exit 1
fi

# Create bucket if it doesn't exist
aws s3 mb s3://$S3_BUCKET --region $AWS_REGION 2>/dev/null || true

# Upload the backup
aws s3 cp $BACKUP_DIR/$BACKUP_FILENAME s3://$S3_BUCKET/$BACKUP_FILENAME --region $AWS_REGION

echo "=========================================="
echo "Backup completed successfully!"
echo "File: $BACKUP_FILENAME"
echo "Location: s3://$S3_BUCKET/$BACKUP_FILENAME"
echo "=========================================="

# Cleanup local backup file
rm -f $BACKUP_DIR/$BACKUP_FILENAME
echo "Local backup file cleaned up."

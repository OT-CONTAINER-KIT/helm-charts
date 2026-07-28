# Outline PVC Backup Scripts

This directory contains scripts to backup the Outline PVC and upload to MinIO or AWS S3.

## Scripts Overview

### 1. `backup-pvc-minio.sh` - Simple MinIO Backup
Basic script to backup PVC and upload to MinIO.

### 2. `backup-pvc-s3.sh` - Simple S3 Backup
Basic script to backup PVC and upload to AWS S3.

### 3. `backup-pvc-advanced.sh` - Advanced Backup
Feature-rich script with:
- Encryption support
- Retention policy
- Configurable storage backend
- Better error handling

## Quick Start

### Prerequisites

1. **kubectl** - Kubernetes command-line tool
2. **MinIO Client (mc)** - For MinIO backups
3. **AWS CLI** - For S3 backups
4. **kubectl access** - To your Kubernetes cluster

### Configuration

Edit the configuration section in the script you want to use:

```bash
# For MinIO
MINIO_ENDPOINT="https://minio.your-domain.com"
MINIO_BUCKET="outline-backups"
MINIO_ACCESS_KEY="your-access-key"
MINIO_SECRET_KEY="your-secret-key"

# For S3
AWS_REGION="us-east-1"
S3_BUCKET="your-outline-backups"
```

### Running the Scripts

#### Simple MinIO Backup
```bash
./backup-pvc-minio.sh
```

#### Simple S3 Backup
```bash
./backup-pvc-s3.sh
```

#### Advanced Backup (with encryption and retention)
```bash
# Edit configuration first
nano backup-pvc-advanced.sh

# Then run
./backup-pvc-advanced.sh
```

## Features

### Backup Format
- Filename: `outline_YYYYMMDD_HHMMSS.tar.gz`
- Example: `outline_20240127_143022.tar.gz`

### Encryption (Advanced Script)
To enable encryption, set in `backup-pvc-advanced.sh`:
```bash
ENABLE_ENCRYPTION=true
ENCRYPTION_PASSPHRASE="your-strong-passphrase"
```

The encrypted file will have `.enc` extension.

### Retention Policy (Advanced Script)
To keep only the last N backups:
```bash
RETENTION_COUNT=10
```

## Storage Backend Options

### MinIO (Self-hosted)
- Pros: Full control, no egress fees, faster transfers
- Cons: Requires infrastructure management

### AWS S3
- Pros: Managed service, high durability, global access
- Cons: Egress fees, requires AWS account

## Troubleshooting

### "kubectl: command not found"
Install kubectl: https://kubernetes.io/docs/tasks/tools/

### "mc: command not found"
The script will auto-install mc, or install manually:
```bash
curl -o /tmp/mc https://dl.min.io/client/mc/release/linux-amd64/mc
chmod +x /tmp/mc
sudo mv /tmp/mc /usr/local/bin/mc
```

### "aws: command not found"
Install AWS CLI:
```bash
pip install awscli
```

### "AWS CLI not configured"
Configure AWS CLI:
```bash
aws configure
```

### Backup pod fails to start
Check if the PVC exists:
```bash
kubectl get pvc -n docs
```

### Permission denied
Make scripts executable:
```bash
chmod +x backup-pvc-*.sh
```

## Automated Backups

### Using Cron
Add to crontab for daily backups:
```bash
# Daily backup at 2 AM
0 2 * * * /path/to/backup-pvc-minio.sh >> /var/log/outline-backup.log 2>&1
```

### Using Kubernetes CronJob
Create a CronJob resource for cluster-native scheduling.

## Security Notes

1. **Never commit credentials** to version control
2. Use **Kubernetes Secrets** for sensitive data
3. Enable **encryption** for sensitive backups
4. Use **IAM roles** instead of access keys when possible
5. Regularly **test restore** procedures

## Restore Procedure

To restore from backup:
```bash
# Download backup from MinIO
mc cp outline-minio/outline-backups/outline_20240127_143022.tar.gz .

# Or from S3
aws s3 cp s3://your-bucket/outline_20240127_143022.tar.gz .

# If encrypted, decrypt first
openssl enc -aes-256-cbc -d -pbkdf2 -in outline_20240127_143022.tar.gz.enc -out outline_20240127_143022.tar.gz -pass pass:your-passphrase

# Restore to PVC (use the restore script from previous conversation)
./restore-pvc.sh outline_20240127_143022.tar.gz
```

## Support

For issues or questions, refer to the main project documentation.

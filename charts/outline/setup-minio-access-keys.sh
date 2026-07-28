#!/bin/bash

# Setup MinIO Access Keys via CLI
# This script installs mc and helps you create access keys for backup

set -e

# ===========================================
# CONFIGURATION - UPDATE THESE
# ===========================================

MINIO_ENDPOINT="https://minio.ldc.opstree.dev:9000"
MINIO_ROOT_USER="minioadmin"
MINIO_ROOT_PASSWORD="opstreeadmin@2510"

# ===========================================
# FUNCTIONS
# ===========================================

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

install_mc() {
    log "Installing MinIO Client (mc)..."

    curl -o /tmp/mc https://dl.min.io/client/mc/release/linux-amd64/mc
    chmod +x /tmp/mc
    sudo mv /tmp/mc /usr/local/bin/mc

    mc --version
    log "MinIO Client installed successfully"
}

configure_mc() {
    log "Configuring MinIO Client..."

    mc alias set outline-minio $MINIO_ENDPOINT $MINIO_ROOT_USER $MINIO_ROOT_PASSWORD

    log "Testing connection..."
    mc ls outline-minio/

    log "MinIO Client configured successfully"
}

create_access_key() {
    log "Creating access key for backup..."

    echo ""
    echo "=========================================="
    echo "Creating Access Key with readwrite policy"
    echo "=========================================="
    echo ""

    # Create access key and capture output
    ACCESS_KEY_OUTPUT=$(mc admin accesskey create outline-minio --name outline-volsync)

    echo "$ACCESS_KEY_OUTPUT"

    # Extract access key from output
    ACCESS_KEY_ID=$(echo "$ACCESS_KEY_OUTPUT" | grep -oP 'Access Key:\s*\K\S+' || echo "")

    # If grep with -oP doesn't work, try alternative parsing
    if [ -z "$ACCESS_KEY_ID" ]; then
        ACCESS_KEY_ID=$(echo "$ACCESS_KEY_OUTPUT" | awk '/Access Key:/{print $3}')
    fi

    if [ -n "$ACCESS_KEY_ID" ]; then
        log "Attaching readwrite policy to access key..."
        mc admin policy attach outline-minio readwrite --user "$ACCESS_KEY_ID"
        log "✅ Policy attached successfully!"
    else
        echo ""
        echo "⚠️  Could not auto-extract Access Key ID."
        echo "Please manually run:"
        echo "  mc admin policy attach outline-minio readwrite --user <YOUR_ACCESS_KEY>"
    fi

    echo ""
    echo "=========================================="
    echo "✅ Access Key Created with readwrite policy!"
    echo "=========================================="
    echo ""
    echo "📋 Copy these credentials:"
    echo ""
    echo "Access Key:  (shown above)"
    echo "Secret Key:  (shown above - COPY IT NOW!)"
    echo ""
    echo "⚠️  Secret Key is shown ONCE. Save it somewhere safe!"
    echo ""
    echo "=========================================="
}

test_access_key() {
    log "Testing access key..."

    echo ""
    echo "Enter the Access Key you just created:"
    read -r ACCESS_KEY

    echo "Enter the Secret Key you just created:"
    read -rs SECRET_KEY
    echo ""

    # Configure mc with new access key
    mc alias set test-access-key $MINIO_ENDPOINT $ACCESS_KEY $SECRET_KEY

    # Test listing bucket
    log "Testing bucket listing..."
    mc ls test-access-key/outline-pvc-backup/

    # Test upload
    log "Testing upload..."
    echo "test" > /tmp/test-upload.txt
    mc cp /tmp/test-upload.txt test-access-key/outline-pvc-backup/test-upload.txt

    # Test download
    log "Testing download..."
    mc cp test-access-key/outline-pvc-backup/test-upload.txt /tmp/test-download.txt

    # Cleanup test file
    mc rm test-access-key/outline-pvc-backup/test-upload.txt
    rm -f /tmp/test-upload.txt /tmp/test-download.txt

    log "✅ Access key works! (read, write, delete all working)"
}

print_next_steps() {
    echo "=========================================="
    echo "📋 Next Steps"
    echo "=========================================="
    echo ""
    echo "1. Update deploy-backup-cronjob.sh with your credentials:"
    echo ""
    echo "   MINIO_ACCESS_KEY=\"<your-access-key>\""
    echo "   MINIO_SECRET_KEY=\"<your-secret-key>\""
    echo ""
    echo "2. Deploy backup CronJob:"
    echo "   ./deploy-backup-cronjob.sh"
    echo ""
    echo "3. Verify backup:"
    echo "   kubectl get cronjob -n docs"
    echo "   kubectl logs -n docs -l app=outline-backup -f"
    echo ""
    echo "=========================================="
}

# ===========================================
# MAIN EXECUTION
# ===========================================

echo "=========================================="
echo "MinIO Access Key Setup"
echo "=========================================="
echo ""
echo "This script will:"
echo "1. Install MinIO Client (mc)"
echo "2. Configure it for your MinIO"
echo "3. Create access key with readwrite policy"
echo ""
echo "=========================================="

# Check if mc is already installed
if command -v mc &> /dev/null; then
    log "MinIO Client already installed"
    mc --version
else
    install_mc
fi

# Configure mc
configure_mc

# Create access key
create_access_key

# Test access key (optional)
echo ""
echo "Do you want to test the access key? (y/n)"
read -r TEST_ACCESS

if [ "$TEST_ACCESS" = "y" ] || [ "$TEST_ACCESS" = "Y" ]; then
    test_access_key
fi

# Print next steps
print_next_steps

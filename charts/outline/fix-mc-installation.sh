#!/bin/bash

# Fix MinIO Client (mc) Installation
# The current mc installation is corrupted (HTML file instead of binary)

set -e

echo "=========================================="
echo "Fixing MinIO Client (mc) Installation"
echo "=========================================="
echo ""

# Remove corrupted mc
echo "Removing corrupted mc installation..."
if [ -f /usr/local/bin/mc ]; then
    sudo rm -f /usr/local/bin/mc
    echo "✅ Removed corrupted /usr/local/bin/mc"
fi

# Also remove from /tmp if exists
rm -f /tmp/mc

# Download mc correctly with following redirects
echo ""
echo "Downloading MinIO Client (mc)..."
curl -L -o /tmp/mc https://dl.min.io/client/mc/release/linux-amd64/mc

# Make executable
chmod +x /tmp/mc

# Move to /usr/local/bin
sudo mv /tmp/mc /usr/local/bin/mc

# Verify installation
echo ""
echo "Verifying installation..."
mc --version

echo ""
echo "=========================================="
echo "✅ MinIO Client (mc) installed successfully!"
echo "=========================================="
echo ""
echo "Now you can run the access key setup script:"
echo "  ./setup-minio-access-keys.sh"
echo ""
echo "=========================================="

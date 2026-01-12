#!/bin/bash
set -e

# Setup Host Directories
echo "Ensuring host directories exist..."

# Vaultwarden Data
if [ ! -d "/opt/cerberus/vaultwarden" ]; then
    echo "Creating /opt/cerberus/vaultwarden..."
    sudo mkdir -p /opt/cerberus/vaultwarden
    # Vaultwarden/Bitwarden often runs as a non-root user (or we map it to one).
    # Ensuring user 1000:1000 (typical uid/gid) owns the directory ensures the container can write to it.
    sudo chown -R 1000:1000 /opt/cerberus/vaultwarden
fi

# Vaultwarden Backups
if [ ! -d "/mnt/storage/backups/vaultwarden" ]; then
    echo "Creating /mnt/storage/backups/vaultwarden..."
    sudo mkdir -p /mnt/storage/backups/vaultwarden
    # Ensure writable by the backup user (assuming 1000:1000 or group write access)
    sudo chown -R 1000:1000 /mnt/storage/backups/vaultwarden
fi

echo "Host setup complete."

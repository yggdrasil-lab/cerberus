#!/bin/bash
set -e

STACK_NAME="${STACK_NAME:-cerberus}"
SERVICE_NAME="${STACK_NAME}_lldap"
VOLUME_NAME="${STACK_NAME}_lldap_data"
BACKUP_DIR="/mnt/storage/backups/lldap"

# Check if run as root/sudo (required for docker commands)
if ! [ -x "$(command -v docker)" ]; then
  echo "Error: Docker command not found. This script must be run on the Docker host."
  exit 1
fi

# If argument is provided, use it. Otherwise, look for the latest backup.
if [ -n "$1" ]; then
  BACKUP_FILE="$1"
else
  echo "No backup file specified. Detecting latest backup..."
  # Find latest .db file in the backup directory
  LATEST_BACKUP=$(ls -t "${BACKUP_DIR}"/lldap_backup_*.db 2>/dev/null | head -n 1)
  if [ -z "${LATEST_BACKUP}" ]; then
    echo "Error: No backups found in ${BACKUP_DIR}."
    exit 1
  fi
  BACKUP_FILE="${LATEST_BACKUP}"
fi

# Ensure backup file exists
if [ ! -f "${BACKUP_FILE}" ]; then
  # Check if it was specified relative to backup directory
  if [ -f "${BACKUP_DIR}/${BACKUP_FILE}" ]; then
    BACKUP_FILE="${BACKUP_DIR}/${BACKUP_FILE}"
  else
    echo "Error: Backup file not found: ${BACKUP_FILE}"
    exit 1
  fi
fi

FILENAME=$(basename "${BACKUP_FILE}")
echo "Selected backup: ${FILENAME} (${BACKUP_FILE})"
read -p "Are you sure you want to restore this backup to LLDAP? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Restore cancelled."
  exit 0
fi

echo "Scaling down ${SERVICE_NAME} to 0 replicas..."
docker service scale "${SERVICE_NAME}=0"

echo "Waiting for service to stop..."
while [ "$(docker service ps -q -f "desired-state=running" "${SERVICE_NAME}" | wc -l)" -gt 0 ]; do
  sleep 1
done

echo "Restoring database to volume ${VOLUME_NAME}..."
# Mount the named volume and the directory containing the backup file, then copy and set permissions (1000:1000 for lldap)
docker run --rm \
  -v "${VOLUME_NAME}:/data" \
  -v "$(dirname "${BACKUP_FILE}"):/backup_source" \
  alpine sh -c "cp /backup_source/${FILENAME} /data/users.db && chown -R 1000:1000 /data/users.db"

echo "Scaling up ${SERVICE_NAME} back to 1 replica..."
docker service scale "${SERVICE_NAME}=1"

echo "LLDAP restore completed successfully!"

#!/bin/bash
set -e

# ==============================================================================
# Authentik Restore Utility
# ==============================================================================
# Restores Authentik PostgreSQL database and /data application directory
# from backups stored in /mnt/storage/backups/authentik.
#
# Usage:
#   ./restore.sh [path_to_db_dump] [path_to_data_tar]
#   ./restore.sh                # Interactive auto-detection of latest backup
# ==============================================================================

STACK_NAME="${STACK_NAME:-cerberus}"
BACKUP_DIR="${BACKUP_DIR:-/mnt/storage/backups/authentik}"
DATA_DIR="${DATA_DIR:-/opt/cerberus/authentik}"
POSTGRES_SERVICE="${STACK_NAME}_authentik-postgres"
SERVER_SERVICE="${STACK_NAME}_authentik-server"
WORKER_SERVICE="${STACK_NAME}_authentik-worker"

if ! command -v docker >/dev/null 2>&1; then
  echo "Error: Docker command not found. This script must be run on the Docker host."
  exit 1
fi

# Detect or validate DB dump file
if [ -n "$1" ]; then
  DB_FILE="$1"
else
  echo "Scanning for latest Authentik database dump in ${BACKUP_DIR}..."
  LATEST_DB=$(ls -t "${BACKUP_DIR}"/authentik_db_*.dump 2>/dev/null | head -n 1)
  if [ -z "${LATEST_DB}" ]; then
    echo "Error: No database dumps found in ${BACKUP_DIR}."
    exit 1
  fi
  DB_FILE="${LATEST_DB}"
fi

if [ ! -f "${DB_FILE}" ]; then
  if [ -f "${BACKUP_DIR}/${DB_FILE}" ]; then
    DB_FILE="${BACKUP_DIR}/${DB_FILE}"
  else
    echo "Error: DB dump file not found: ${DB_FILE}"
    exit 1
  fi
fi

# Detect or validate data archive
if [ -n "$2" ]; then
  DATA_FILE="$2"
else
  # Extract timestamp pattern from db filename if possible: authentik_db_YYYYMMDD_HHMMSS.dump
  TIMESTAMP=$(basename "${DB_FILE}" | sed -E 's/authentik_db_([0-9]{8}_[0-9]{6})\.dump/\1/')
  if [ -f "${BACKUP_DIR}/authentik_data_${TIMESTAMP}.tar.gz" ]; then
    DATA_FILE="${BACKUP_DIR}/authentik_data_${TIMESTAMP}.tar.gz"
  else
    DATA_FILE=$(ls -t "${BACKUP_DIR}"/authentik_data_*.tar.gz 2>/dev/null | head -n 1)
  fi
fi

echo "=============================================================================="
echo "Authentik Restore Targets:"
echo "  Database Dump: $(basename "${DB_FILE}")"
if [ -n "${DATA_FILE}" ] && [ -f "${DATA_FILE}" ]; then
  echo "  Data Archive:  $(basename "${DATA_FILE}")"
else
  echo "  Data Archive:  None (skipping data restore)"
fi
echo "  Destination:   PostgreSQL (${POSTGRES_SERVICE}) & ${DATA_DIR}"
echo "=============================================================================="

read -p "Are you sure you want to restore Authentik from this backup? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Restore cancelled."
  exit 0
fi

echo "Step 1: Scaling down ${SERVER_SERVICE} and ${WORKER_SERVICE} to 0 replicas..."
docker service scale "${SERVER_SERVICE}=0" "${WORKER_SERVICE}=0"

echo "Waiting for services to terminate..."
while [ "$(docker service ps -q -f "desired-state=running" "${SERVER_SERVICE}" 2>/dev/null | wc -l)" -gt 0 ] || \
      [ "$(docker service ps -q -f "desired-state=running" "${WORKER_SERVICE}" 2>/dev/null | wc -l)" -gt 0 ]; do
  sleep 1
done

echo "Step 2: Locating active PostgreSQL container for ${POSTGRES_SERVICE}..."
PG_CONTAINER=$(docker ps --filter "name=${POSTGRES_SERVICE}" --format "{{.ID}}" | head -n 1)
if [ -z "${PG_CONTAINER}" ]; then
  echo "Error: Could not locate running container for ${POSTGRES_SERVICE}."
  echo "Scaling services back up..."
  docker service scale "${SERVER_SERVICE}=1" "${WORKER_SERVICE}=1"
  exit 1
fi

echo "Step 3: Restoring PostgreSQL database from ${DB_FILE}..."
docker exec -i "${PG_CONTAINER}" pg_restore -U authentik -d authentik --clean --if-exists < "${DB_FILE}"
echo "  PostgreSQL restore finished successfully."

if [ -n "${DATA_FILE}" ] && [ -f "${DATA_FILE}" ]; then
  echo "Step 4: Restoring application data to ${DATA_DIR}..."
  mkdir -p "${DATA_DIR}"
  tar -xzf "${DATA_FILE}" -C "${DATA_DIR}"
  chown -R 1000:1000 "${DATA_DIR}"
  echo "  Application data restore finished successfully."
fi

echo "Step 5: Scaling up ${SERVER_SERVICE} and ${WORKER_SERVICE} back to 1 replica..."
docker service scale "${SERVER_SERVICE}=1" "${WORKER_SERVICE}=1"

echo "Waiting for Authentik server to become ready..."
sleep 5

echo "Authentik restore completed successfully!"

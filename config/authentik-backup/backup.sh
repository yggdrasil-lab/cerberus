#!/bin/sh
set -e

BACKUP_DIR="/backup"
DB_NAME="authentik"
DB_USER="authentik"
DB_HOST="authentik-postgres"
BACKUP_FILE="${BACKUP_DIR}/authentik_db_$(date +%Y%m%d_%H%M%S).dump"
DATA_FILE="${BACKUP_DIR}/authentik_data_$(date +%Y%m%d_%H%M%S).tar.gz"

echo "[$(date)] Starting Authentik backup..."

# Read Postgres password from the mounted Docker secret
PGPASSWORD="$(cat /run/secrets/cerberus_authentik_postgres_password)"
export PGPASSWORD

mkdir -p "${BACKUP_DIR}"

# 1. PostgreSQL dump (consistent snapshot, custom format)
echo "[$(date)] Dumping PostgreSQL database (${DB_NAME})..."
pg_dump -h "${DB_HOST}" -U "${DB_USER}" -d "${DB_NAME}" -F c -f "${BACKUP_FILE}"
echo "[$(date)] DB dump complete: ${BACKUP_FILE}"

# 2. Application data archive (media, avatars, icons, certs)
echo "[$(date)] Archiving /data (media, certs, templates)..."
tar -czf "${DATA_FILE}" -C /data .
echo "[$(date)] Data archive complete: ${DATA_FILE}"

# 3. Prune backups older than BACKUP_KEEP_DAYS (default 30 days)
KEEP_DAYS=${BACKUP_KEEP_DAYS:-30}
echo "[$(date)] Pruning backups older than ${KEEP_DAYS} days..."
find "${BACKUP_DIR}" -name "authentik_*" -mtime +${KEEP_DAYS} -delete

echo "[$(date)] Authentik backup completed successfully."

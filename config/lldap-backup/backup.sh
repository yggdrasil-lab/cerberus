#!/bin/sh
set -e

BACKUP_DIR="/backup"
DB_FILE="/data/users.db"
BACKUP_FILE="${BACKUP_DIR}/lldap_backup_$(date +%Y%m%d_%H%M%S).db"

echo "[$(date)] Starting LLDAP SQLite database backup..."

if [ -f "${DB_FILE}" ]; then
  mkdir -p "${BACKUP_DIR}"
  # Run sqlite3 backup command to ensure consistency
  sqlite3 "${DB_FILE}" ".backup '${BACKUP_FILE}'"
  echo "[$(date)] LLDAP backup completed: ${BACKUP_FILE}"
  
  # Prune backups older than BACKUP_KEEP_DAYS (default 30 days)
  KEEP_DAYS=${BACKUP_KEEP_DAYS:-30}
  echo "[$(date)] Pruning backups older than ${KEEP_DAYS} days..."
  find "${BACKUP_DIR}" -name "lldap_backup_*.db" -mtime +${KEEP_DAYS} -delete
else
  echo "[$(date)] ERROR: SQLite database file not found at ${DB_FILE}"
  exit 1
fi

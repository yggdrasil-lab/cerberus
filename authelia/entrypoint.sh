#!/bin/sh
set -euo pipefail

HOST="${LLDAP_HOST:-lldap}"
PORT="${LLDAP_PORT:-3890}"

REDIS_HOST="${REDIS_HOST:-authelia-redis}"
REDIS_PORT="${REDIS_PORT:-6379}"

POSTGRES_HOST="${POSTGRES_HOST:-authelia-postgres}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"

MAX_RETRIES="${MAX_RETRIES:-30}"

echo "Waiting for LLDAP at $HOST:$PORT to be ready..."
RETRIES=0
while ! nc -w 1 "$HOST" "$PORT" < /dev/null > /dev/null 2>&1; do
  RETRIES=$((RETRIES + 1))
  if [ "$RETRIES" -ge "$MAX_RETRIES" ]; then
    echo "ERROR: Timed out waiting for LLDAP at $HOST:$PORT after $MAX_RETRIES attempts" >&2
    exit 1
  fi
  echo "Waiting for LLDAP at $HOST:$PORT to be ready..."
  sleep 1
done

echo "Waiting for Redis at $REDIS_HOST:$REDIS_PORT to be ready..."
RETRIES=0
while ! nc -w 1 "$REDIS_HOST" "$REDIS_PORT" < /dev/null > /dev/null 2>&1; do
  RETRIES=$((RETRIES + 1))
  if [ "$RETRIES" -ge "$MAX_RETRIES" ]; then
    echo "ERROR: Timed out waiting for Redis at $REDIS_HOST:$REDIS_PORT after $MAX_RETRIES attempts" >&2
    exit 1
  fi
  echo "Waiting for Redis at $REDIS_HOST:$REDIS_PORT to be ready..."
  sleep 1
done

echo "Waiting for Postgres at $POSTGRES_HOST:$POSTGRES_PORT to be ready..."
RETRIES=0
while ! nc -w 1 "$POSTGRES_HOST" "$POSTGRES_PORT" < /dev/null > /dev/null 2>&1; do
  RETRIES=$((RETRIES + 1))
  if [ "$RETRIES" -ge "$MAX_RETRIES" ]; then
    echo "ERROR: Timed out waiting for Postgres at $POSTGRES_HOST:$POSTGRES_PORT after $MAX_RETRIES attempts" >&2
    exit 1
  fi
  echo "Waiting for Postgres at $POSTGRES_HOST:$POSTGRES_PORT to be ready..."
  sleep 1
done

echo "LLDAP, Redis, and Postgres are ready! Starting Authelia..."

# Execute the original command
exec /app/authelia --config /config/configuration.yml

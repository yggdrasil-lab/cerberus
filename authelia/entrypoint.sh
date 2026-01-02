#!/bin/sh

HOST="${LLDAP_HOST:-lldap}"
PORT="${LLDAP_PORT:-3890}"

REDIS_HOST="${REDIS_HOST:-authelia-redis}"
REDIS_PORT="${REDIS_PORT:-6379}"

POSTGRES_HOST="${POSTGRES_HOST:-authelia-postgres}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"

echo "Waiting for LLDAP at $HOST:$PORT to be ready..."

while ! nc -w 1 "$HOST" "$PORT" < /dev/null > /dev/null 2>&1; do
  echo "Waiting for LLDAP at $HOST:$PORT to be ready..."
  sleep 1
done

echo "Waiting for Redis at $REDIS_HOST:$REDIS_PORT to be ready..."
while ! nc -w 1 "$REDIS_HOST" "$REDIS_PORT" < /dev/null > /dev/null 2>&1; do
  echo "Waiting for Redis at $REDIS_HOST:$REDIS_PORT to be ready..."
  sleep 1
done

echo "Waiting for Postgres at $POSTGRES_HOST:$POSTGRES_PORT to be ready..."
while ! nc -w 1 "$POSTGRES_HOST" "$POSTGRES_PORT" < /dev/null > /dev/null 2>&1; do
  echo "Waiting for Postgres at $POSTGRES_HOST:$POSTGRES_PORT to be ready..."
  sleep 1
done

echo "LLDAP, Redis, and Postgres are ready! Starting Authelia..."

# Execute the original command
exec /app/authelia --config /config/configuration.yml

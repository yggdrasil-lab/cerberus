#!/bin/sh

HOST="${LLDAP_HOST:-lldap}"
PORT="${LLDAP_PORT:-3890}"

echo "Waiting for LLDAP at $HOST:$PORT to be ready..."

# Wait for LLDAP to be reachable on the specified host and port
# BusyBox nc doesn't support -z, so we connect with timeout and immediate close
# Redirect output to null to avoid "bad address" errors during DNS propagation
while ! nc -w 1 "$HOST" "$PORT" < /dev/null > /dev/null 2>&1; do
  echo "Waiting for LLDAP at $HOST:$PORT to be ready..."
  sleep 1
done

echo "LLDAP is ready! Starting Authelia..."

# Execute the original command
exec /app/authelia --config /config/configuration.yml

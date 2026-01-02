#!/bin/bash
set -e

# Environment variables are expected to be set in the shell/CI environment

echo "Removing existing Cerberus stack..."
docker stack rm cerberus || true

echo "Waiting for stack to be removed..."
while docker service ls | grep -q "cerberus_"; do
    echo "Stack services still active, waiting..."
    sleep 2
done

echo "Waiting for network to be removed..."
while docker network ls | grep -q "cerberus_internal"; do
    echo "Stack network still active, waiting..."
    sleep 2
done

echo "Building images..."
docker compose build

echo "Deploying Cerberus stack to Swarm (Production Mode)..."

# Deploy the stack
# --prune: Remove services that are no longer referenced in the compose file
docker stack deploy --prune -c docker-compose.yml -c docker-compose.prod.yml cerberus

echo "Deployment command submitted. Check status with: docker stack services cerberus"

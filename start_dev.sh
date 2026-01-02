#!/bin/bash
set -e

# Load environment variables (Required for Dev)
if [ -f .env ]; then
    echo "Loading environment variables from .env..."
    set -a
    source .env
    set +a
else
    echo "Error: .env file not found. Please create it by copying .env.example:"
    echo "  cp .env.example .env"
    echo "Then update it with your configuration and secrets."
    exit 1
fi

STACK_NAME="cerberus_dev"

echo "Removing existing ${STACK_NAME} stack..."
docker stack rm ${STACK_NAME} || true

echo "Waiting for stack to be removed..."
while docker service ls | grep -q "${STACK_NAME}_"; do
    echo "Stack services still active, waiting..."
    sleep 2
    sleep 2
done

echo "Waiting for network to be removed..."
while docker network ls | grep -q "${STACK_NAME}_internal"; do
    echo "Stack network still active, waiting..."
    sleep 2
done

echo "Building images..."
docker compose build

echo "Deploying ${STACK_NAME} stack to Swarm (Dev Mode)..."

# Deploy the stack
# --prune: Remove services that are no longer referenced
# --resolve-image always: Always check for newer images
docker stack deploy --prune -c docker-compose.yml -c docker-compose.dev.yml ${STACK_NAME}

echo "Deployment command submitted. Check status with: docker stack services ${STACK_NAME}"

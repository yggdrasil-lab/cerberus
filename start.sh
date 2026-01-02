#!/bin/bash
set -e

# Environment variables are expected to be set in the shell/CI environment
export STACK_NAME="cerberus"
# Set project name so built images are labeled with the correct stack name
export COMPOSE_PROJECT_NAME="${STACK_NAME}"

echo "Removing existing ${STACK_NAME} stack..."
docker stack rm ${STACK_NAME} || true

echo "Waiting for stack to be removed..."
while docker service ls | grep -q "${STACK_NAME}_"; do
    echo "Stack services still active, waiting..."
    sleep 2
done

echo "Waiting for network to be removed..."
while docker network ls | grep -q "${STACK_NAME}_internal"; do
    echo "Stack network still active, waiting..."
    sleep 2
done

echo "Building images..."
docker compose build

echo "Deploying ${STACK_NAME} stack to Swarm (Production Mode)..."

# Deploy the stack
# --prune: Remove services that are no longer referenced in the compose file
docker stack deploy --prune -c docker-compose.yml -c docker-compose.prod.yml ${STACK_NAME}

echo "Deployment command submitted. Check status with: docker stack services ${STACK_NAME}"

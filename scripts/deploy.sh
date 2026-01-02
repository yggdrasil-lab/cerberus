#!/bin/bash
set -e

# Usage: ./deploy.sh [--skip-build] <STACK_NAME> [COMPOSE_FILES...]
# Example: ./deploy.sh cerberus_dev docker-compose.yml docker-compose.dev.yml

SKIP_BUILD=false
STACK_NAME=""
COMPOSE_FILES=()

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-build)
            SKIP_BUILD=true
            shift
            ;;
        *)
            if [ -z "$STACK_NAME" ]; then
                STACK_NAME="$1"
            else
                COMPOSE_FILES+=("$1")
            fi
            shift
            ;;
    esac
done

if [ -z "$STACK_NAME" ]; then
    echo "Usage: $0 [--skip-build] <STACK_NAME> [COMPOSE_FILES...]"
    exit 1
fi

# Default to docker-compose.yml if no files provided
if [ ${#COMPOSE_FILES[@]} -eq 0 ]; then
    COMPOSE_FILES=("docker-compose.yml")
fi

# Construct flag strings
BUILD_ARGS=""
DEPLOY_ARGS=""

for file in "${COMPOSE_FILES[@]}"; do
    BUILD_ARGS="$BUILD_ARGS -f $file"
    DEPLOY_ARGS="$DEPLOY_ARGS -c $file"
done

export STACK_NAME
# Set project name so built images are labeled with the correct stack name
export COMPOSE_PROJECT_NAME="${STACK_NAME}"

echo "Starting deployment for stack: ${STACK_NAME}"
echo "Using compose files: ${COMPOSE_FILES[*]}"

# --- Cleanup ---
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

# --- Build ---
if [ "$SKIP_BUILD" = true ]; then
    echo "Skipping build step..."
else
    echo "Building images..."
    # shellcheck disable=SC2086
    docker compose $BUILD_ARGS build
fi

# --- Deploy ---
echo "Deploying ${STACK_NAME} stack to Swarm..."
# --prune: Remove services that are no longer referenced matched by the compose files
# shellcheck disable=SC2086
docker stack deploy --prune $DEPLOY_ARGS "${STACK_NAME}"

echo "Deployment command submitted. Check status with: docker stack services ${STACK_NAME}"

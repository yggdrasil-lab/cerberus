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

# Deploy using the shared script
# Passes the stack name and the compose files configuration
./scripts/deploy.sh "cerberus_dev" docker-compose.yml docker-compose.dev.yml

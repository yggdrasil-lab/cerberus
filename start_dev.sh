#!/bin/bash
set -e

# Load environment variables (Required for Dev)
source ./scripts/load_env.sh

# Deploy using the shared script
# Passes the stack name and the compose files configuration
./scripts/deploy.sh "cerberus_dev" docker-compose.yml docker-compose.dev.yml

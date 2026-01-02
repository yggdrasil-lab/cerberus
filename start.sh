#!/bin/bash
set -e

# Deploy using the shared script
# Passes the stack name and the compose files configuration
./scripts/deploy.sh "cerberus" docker-compose.yml docker-compose.prod.yml

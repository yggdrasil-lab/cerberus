#!/bin/bash
set -e

# Deploy using the shared script relative to the current directory
# scripts/deploy.sh loads the .env file automatically
./scripts/deploy.sh "cerberus_dev" docker-compose.yml docker-compose.dev.yml

#!/bin/bash



# Check if .env file exists
if [ ! -f .env ]; then
    echo "Error: .env file not found. Please create it by copying .env.example:"
    echo "  cp .env.example .env"
    echo "Then update it with your configuration and secrets."
    exit 1
fi

# Run docker compose
echo "Starting development environment..."
docker compose -f docker-compose.yml -f docker-compose.dev.yml down --remove-orphans
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d --remove-orphans

echo "Development environment started."
docker compose -f docker-compose.yml -f docker-compose.dev.yml logs -f

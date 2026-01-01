#!/bin/bash
set -e

# 1. Pull latest images
docker compose -f docker-compose.yml -f docker-compose.prod.yml pull

# 2. Create containers (initializes volumes without starting)
docker compose -f docker-compose.yml -f docker-compose.prod.yml create

# 3. Copy configuration into the named volume via the container
# We copy the *contents* of config/ into /config inside the container
docker cp ./config/. authelia:/config/

# 4. Fix permissions inside the volume
# We use a temporary alpine container mounting the volumes from 'authelia'
# to chown the files to 1000:1000
docker run --rm --volumes-from authelia alpine chown -R 1000:1000 /config

# 5. Start the stack
docker compose -f docker-compose.yml -f docker-compose.prod.yml down --remove-orphans
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d --remove-orphans

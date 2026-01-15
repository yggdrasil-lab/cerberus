#!/bin/bash
set -e

# Load environment variables
if [ -f .env ]; then
    set -a
    source .env
    set +a
fi

chmod +x scripts/ensure_secret.sh

# Define Secrets Map for Local Dev
declare -A SECRETS=(
  ["cerberus_jwt_secret"]="JWT_SECRET"
  ["cerberus_session_secret"]="SESSION_SECRET"
  ["cerberus_storage_encryption_key"]="STORAGE_ENCRYPTION_KEY"
  ["cerberus_postgres_password"]="POSTGRES_PASSWORD"
  ["cerberus_lldap_jwt_secret"]="LLDAP_JWT_SECRET"
  ["cerberus_lldap_key_seed"]="LLDAP_KEY_SEED"
  ["cerberus_lldap_user_pass"]="LLDAP_LDAP_USER_PASS"
  ["cerberus_vw_admin_token"]="VW_ADMIN_TOKEN"
)

# Generate Secrets and Export Names
echo "Generating local secrets..."
for SECRET_NAME in "${!SECRETS[@]}"; do
  ENV_VAR=${SECRETS[$SECRET_NAME]}
  SECRET_VALUE="${!ENV_VAR}"
  
  if [ -z "$SECRET_VALUE" ]; then
    echo "Warning: $ENV_VAR is missing from .env"
    continue
  fi

  # Create/Update secret and get versioned name
  # Use 'cerberus_dev' prefix or keep standard 'cerberus' prefix?
  # CI/CD uses 'cerberus' prefix. Local dev usually shares secrets or uses dev variants.
  # Let's keep the base names as defined in the map.
  VERSIONED_NAME=$(echo "$SECRET_VALUE" | ./scripts/ensure_secret.sh "$SECRET_NAME")
  
  # Export XXX_NAME variable for docker-compose
  export "${ENV_VAR}_NAME"="$VERSIONED_NAME"
done

# Deploy using the shared script relative to the current directory
# scripts/deploy.sh loads the .env file automatically (again, but harmless)
./scripts/deploy.sh "cerberus_dev" docker-compose.yml docker-compose.dev.yml

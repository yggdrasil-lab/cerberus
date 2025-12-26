# Cerberus - Identity & Access Management

This project deploys **Authelia**, backed by **PostgreSQL** and **Redis**, to provide Single Sign-On (SSO) and authentication for your infrastructure.

## Architecture

- **Authelia**: Main authentication server.
- **PostgreSQL**: Persistent storage for user preferences and OIDC tokens.
- **Redis**: Session storage.
- **Network**: Connects to the external `aether-net` network to communicate with Traefik ("Olympus").

## Directory Structure

```
cerberus/
├── .github/workflows/   # CI/CD pipelines
├── config/
│   ├── configuration.yml    # Main Authelia config
│   ├── users_database.yml   # File-based user backend
│   ├── notification.txt     # Emails land here (for now)
│   └── secrets/             # Secrets (generated)
├── .env.example             # Template for environment variables
└── docker-compose.yml
```

## Setup & Deployment

### 1. Prerequisites

- **Network**: Ensure the external network `aether-net` exists (created by your Traefik stack).
    ```bash
    docker network create aether-net || true
    ```

### 2. Configuration

**Environment Variables:**
Copy `.env.example` to `.env` and adjust the values:
```bash
cp .env.example .env
```
- `DOMAIN_NAME`: Your main domain (e.g., `tienzo.net`).
- `AUTHELIA_SUBDOMAIN`: Subdomain for the auth portal (e.g., `auth`).

**Secrets:**
Ensure the following files exist in `config/secrets/` (generated via script or manually):
- `jwt_secret`
- `session_secret`
- `postgres_password`
- `storage_encryption_key`

### 3. Start

```bash
docker compose up -d
```

### 4. User Management

- A default `admin` user has been created in `config/users_database.yml`.
- **IMPORTANT**: You must update the password hash for this user.
- Generate a new password hash:
  ```bash
  docker compose run --rm authelia authelia crypto hash generate argon2id --password 'YourNewPassword'
  ```
- Update `config/users_database.yml` with the output.
- Restart Authelia: `docker compose restart authelia`.

## CI/CD (GitHub Actions)

The repository includes a GitHub Actions workflow (`deploy.yml`) to validate configuration on push to `main`.

**Required Repository Secrets:**
- `JWT_SECRET`
- `SESSION_SECRET`
- `POSTGRES_PASSWORD`
- `STORAGE_ENCRYPTION_KEY`

**Required Repository Variables:**
- `DOMAIN_NAME`
- `AUTHELIA_SUBDOMAIN`

## Integration with Traefik ("Olympus")

This stack registers a middleware named `authelia@docker`.

### Protecting other Services

To protect another service (e.g., `grafana`) in your "Olympus" or other stacks, add these labels to that service's `docker-compose.yml`:

```yaml
labels:
  - "traefik.http.routers.grafana.middlewares=authelia@docker"
```

### Forward Auth Configuration

The middleware is configured automatically via labels on the `authelia` container. It uses the environment variables to set the correct redirection URLs:

```yaml
- "traefik.http.middlewares.authelia.forwardauth.address=http://authelia:9091/api/verify?rd=https://${AUTHELIA_SUBDOMAIN}.${DOMAIN_NAME}"
```

## Security Notes

- **Secrets**: In production, ensure `config/secrets/` files are restricted (chmod 600).
- **TLS**: This setup assumes Traefik handles SSL termination.
- **Notifier**: Currently set to `filesystem` (`config/notification.txt`). For production, configure SMTP in `config/configuration.yml`.
- **Data Persistence**: Data is stored in named Docker volumes (`cerberus_postgres_data` and `cerberus_redis_data`).
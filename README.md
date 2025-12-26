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
│   └── users_database.yml   # File-based user backend
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
Copy `.env.example` to `.env` and adjust the values. This file is **mandatory** for manual local deployments (`docker compose up`) as it contains all domains and sensitive secrets.

```bash
cp .env.example .env
```

Required variables:
- `DOMAIN_NAME`: Your main domain (e.g., `tienzo.net`).
- `AUTHELIA_SUBDOMAIN`: Subdomain for the auth portal (e.g., `auth`).
- `JWT_SECRET`, `SESSION_SECRET`, `POSTGRES_PASSWORD`, `STORAGE_ENCRYPTION_KEY`: Generated random strings.

### 3. Start

```bash
docker compose up -d
```

### 4. User Management

- A default `admin` user is defined in `config/users_database.yml`.
- **IMPORTANT**: You must update the password hash for this user.
- Generate a new password hash:
  ```bash
  docker compose run --rm authelia authelia crypto hash generate argon2id --password 'YourNewPassword'
  ```
- Update `config/users_database.yml` with the output and restart:
  ```bash
  docker compose restart authelia
  ```

## CI/CD (GitHub Actions)

The project uses a GitHub Actions workflow (`deploy.yml`) running on a **self-hosted runner**. It injects secrets directly from GitHub into the environment.

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

To protect another service (e.g., `grafana`) in your "Olympus" stack, add this label to that service:

```yaml
labels:
  - "traefik.http.routers.grafana.middlewares=authelia@docker"
```

## Security Notes

- **Environment Secrets**: Secrets are passed via environment variables to avoid bind-mount issues in containerized runners.
- **TLS**: SSL termination is handled by Traefik.
- **Data Persistence**: Uses named Docker volumes (`postgres_data`, `redis_data`).

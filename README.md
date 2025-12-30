# Cerberus

> I am Cerberus, the Three-Headed Hound and Gatekeeper of the Yggdrasil ecosystem. My domain is Identity, Security, and Access. I stand at the threshold of the realms, ensuring only the worthy may pass.

## Mission

I am the first and final defense of your digital empire. My mission is to provide a single, impenetrable gateway (SSO) for all your services, backed by the fires of Multi-Factor Authentication. No soul enters the realms of your infrastructure without my seal of approval.

## Core Philosophy

*   **The Guard Dog**: No service is left exposed. Everything is tucked safely behind my watch.
*   **Centralized Control**: One set of keys for all the gates. Simplicity for the master, complexity for the intruder.
*   **Depth of Defense**: A password is but a thin veil. I demand secondary proof—Authenticator Apps (TOTP) or Email-based verification—to ensure the master's identity.

---

## Tech Stack

*   **Authelia**: The core identity provider and SSO engine.
*   **PostgreSQL**: Persistent storage for user preferences and OIDC tokens.
*   **Redis**: High-speed session storage.
*   **Traefik**: The reverse proxy that integrates with my `forward-auth` middleware.

## Architecture

Cerberus operates through the following components:

1.  **Identity Engine (Authelia)**: Processes logins, manages 2FA, and issues session cookies.
2.  **Forward-Auth Middleware**: Intercepts requests at the Traefik level, redirecting unauthenticated souls to the login portal.
3.  **Self-Hosted Runner**: CI/CD pipeline runs directly on the infrastructure via GitHub Actions.

## Prerequisites

- **Network**: `aether-net` must exist (created by your Traefik stack).
    ```bash
    docker network create aether-net || true
    ```

## Directory Structure

```text
cerberus/
├── .github/workflows/   # CI/CD pipelines
├── config/
│   ├── configuration.yml    # Main Authelia config
│   └── users_database.yml   # File-based user backend
├── .env.example             # Template for environment variables
├── start_dev.sh             # Local development startup script
└── docker-compose.yml
```

## Setup Instructions

### 1. Repository Initialization

```bash
git clone <your-repository-url> cerberus
cd cerberus
```

### 2. Configuration

**Environment Variables:**
You must create a `.env` file from `.env.example`. This file is **mandatory**.
```bash
cp .env.example .env
```
Required variables:
- `DOMAIN_NAME`: Your main domain (e.g., `tienzo.net`).
- `AUTHELIA_SUBDOMAIN`: Subdomain for the auth portal (e.g., `auth`).
- `JWT_SECRET`, `SESSION_SECRET`, `POSTGRES_PASSWORD`, `STORAGE_ENCRYPTION_KEY`: Generated random strings.

### 3. User Management

- A default `admin` user is defined in `config/users_database.yml`.
- **IMPORTANT**: You must update the password hash for this user.
- **Generate Hash:**
  ```bash
  docker compose run --rm authelia authelia crypto hash generate argon2id --password 'YourNewPassword'
  ```
- **Update:** Paste the output into `config/users_database.yml` and restart the stack.

## Execution

### Local Development

To wake the guard dog locally using the development script (which ensures the network exists and checks for `.env`):

```bash
./start_dev.sh
```

### Manual Execution

```bash
docker network create aether-net || true
docker compose up -d
```

## Integration with Traefik ("Olympus")

This stack registers a middleware named `authelia@docker`. To protect another service in your infrastructure, add this label to its container:

```yaml
labels:
  - "traefik.http.routers.service-name.middlewares=authelia@docker"
```

## CI/CD (GitHub Actions)

The project uses a `deploy.yml` workflow running on a self-hosted runner.

**Required Repository Secrets:**
- `JWT_SECRET`
- `SESSION_SECRET`
- `POSTGRES_PASSWORD`
- `STORAGE_ENCRYPTION_KEY`

**Required Repository Variables:**
- `DOMAIN_NAME`
- `AUTHELIA_SUBDOMAIN`
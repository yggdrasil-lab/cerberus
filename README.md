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
*   **LLDAP**: Lightweight LDAP server for user management.
*   **Vaultwarden**: Self-hosted password manager (Bitwarden compatible).
*   **PostgreSQL**: Persistent storage for user preferences and OIDC tokens.
*   **Redis**: High-speed session storage.
*   **Traefik**: The reverse proxy that integrates with my `forward-auth` middleware.
*   **Hermes**: (External) Simple SMTP relay for sending emails from Authelia and Vaultwarden.

## Architecture

Cerberus operates through the following components:

1.  **Identity Engine (Authelia)**: Processes logins, manages 2FA, and issues session cookies.
2.  **User Directory (LLDAP)**: Stores identities and groups.
3.  **Secrets Management (Vaultwarden)**: Secure storage for passwords and notes.
4.  **Forward-Auth Middleware**: Intercepts requests at the Traefik level, redirecting unauthenticated souls to the login portal.
5.  **Self-Hosted Runner**: CI/CD pipeline runs directly on the infrastructure via GitHub Actions.

## Prerequisites

- **Platform Setup**: Swarm and Network must be initialized (see `Forge/yggdrasil-os`).

## Directory Structure

```text
cerberus/
├── .github/workflows/   # CI/CD pipelines
├── config/
│   ├── configuration.yml    # Main Authelia config
├── .env.example             # Template for environment variables
├── setup_host.sh            # Host preparation script (One-time run)
├── start_dev.sh             # Local development startup script (Swarm)
├── docker-compose.yml       # Base configuration
├── docker-compose.prod.yml  # Production overrides (placement constraints, etc)
└── docker-compose.dev.yml   # Development overrides (ports, logging)
```

## Setup Instructions

### 1. Repository Initialization

```bash
git clone <your-repository-url> cerberus
cd cerberus
```

### 2. Host Preparation

Run the setup script **once** on the target node (e.g., **Muspelheim**) to create the required directories on the host:

```bash
chmod +x setup_host.sh
./setup_host.sh
```

### 3. Configuration

**Environment Variables (.env):**
Create a `.env` file from `.env.example`. 
> [!IMPORTANT]
> In this new architecture, variables defined here are used to **generate Immutable Docker Secrets** during deployment. The services themselves read these secrets from files (e.g., `/run/secrets/xxx`), not directly from environment variables.

```bash
cp .env.example .env
```
Required variables:
- `DOMAIN_NAME`: Your main domain (e.g., `yourdomain.com`).
- `JWT_SECRET`, `SESSION_SECRET`, `POSTGRES_PASSWORD`, `STORAGE_ENCRYPTION_KEY`: Secrets for Authelia.
- `LLDAP_JWT_SECRET`, `LLDAP_KEY_SEED`, `LLDAP_LDAP_USER_PASS`: Secrets for LLDAP.
- `VW_ADMIN_TOKEN`: Argon2 hash for the Vaultwarden Admin Panel (generated via instructions below).

### 4. User Management (LLDAP)

- Access the LLDAP dashboard at `https://ldap.<your-domain>`.
- **Default Admin**: `admin`.
- **Password**: The value of `LLDAP_LDAP_USER_PASS` set in your `.env`.
- **Create Users**: Add users via the LLDAP web interface.
- **Groups**: Create groups (e.g., `admins`) to match your Authelia access policies.

> [!NOTE]
> **Double Login**: When accessing the LLDAP dashboard, you will be prompted to log in **twice**.
> 1.  **Authelia**: Verifies your identity and checks for 2FA.
> 2.  **LLDAP**: A second login screen for the LLDAP internal admin interface.
> This is a known limitation as LLDAP does not widely support header-based authentication for its web UI.

### 5. Secrets Management (Vaultwarden)

Vaultwarden is configured to host your passwords and secure notes.

**Admin Panel & Token Generation:**
To enable the `/admin` interface, you must configure the `ADMIN_TOKEN`. We store this securely as a Docker Secret.

1.  **Generate Password:** Create a strong, unique password (e.g., using Bitwarden's generator).
2.  **Generate Hash:** Run the following command to hash it using Argon2:
    ```bash
    docker run --rm -it vaultwarden/server /vaultwarden hash
    ```
3.  **Input:** Paste your password when prompted (it will be hidden).
4.  **Save:** Copy the resulting string (starting with `$argon2...`). This is the value used for the secret.

**Initial Setup (Account Creation):**
1.  **Enable Signups:** In `docker-compose.yml`, ensure `SIGNUPS_ALLOWED=true`.
2.  **Deploy:** Deploy the stack (`./scripts/deploy.sh "cerberus" docker-compose.yml docker-compose.prod.yml`).
3.  **Register:** Navigate to `https://vault.<your-domain>` and create your **Primary Account**.
4.  **Disable Signups (CRITICAL):**
    *   Edit `docker-compose.yml` and set `SIGNUPS_ALLOWED=false`.
    *   Redeploy (`./scripts/deploy.sh "cerberus" docker-compose.yml docker-compose.prod.yml`) to lock the gates.
    *   Future users can only be invited by the admin.

**Client Setup (Mobile/Desktop):**
1.  Download the **Bitwarden** app (iOS/Android/Desktop).
2.  **Server URL:** Before logging in, tap the **Settings/Gear icon**.
    *   Enter your Self-Hosted URL: `https://vault.<your-domain>`
3.  **Login:** Use the email and master password you created.
4.  **2FA:** It is highly recommended to setup TOTP or FIDO2 key immediately within the Vaultwarden settings.

### 6. Backup & Recovery

**Strategy:**
*   **Producer:** The `vaultwarden-backup` sidecar dumps an encrypted ZIP of the database + attachments daily at 3 AM.
*   **Location:** `/mnt/storage/backups/vaultwarden/` on Muspelheim.
*   **Encryption:** Backups are ZIP encrypted.
    *   **Default Password:** `WHEREISMYPASSWORD?` (Change this via `ZIP_PASSWORD` env var if desired).

**Restoration Steps:**
1.  **Stop Services:** `docker service scale cerberus_vaultwarden=0`
2.  **Locate Backup:** Find the latest zip in `/mnt/storage/backups/vaultwarden/`.
3.  **Extract:** Unzip using the password.
4.  **Restore:** Replace the contents of `/opt/cerberus/vaultwarden/` with the extracted data.
5.  **Restart:** `docker service scale cerberus_vaultwarden=1`

## Execution

### Local Development (Swarm)

To deploy the stack locally using the development script (which loads `.env` and deploys to stack `cerberus_dev`):

```bash
./start_dev.sh
```

### Production Deployment (Swarm)

The deployment pipeline relies on the standardized `ops-scripts` submodule. **Ensure you have run `./setup_host.sh` at least once before deploying.**

```bash
./scripts/deploy.sh "cerberus" docker-compose.yml docker-compose.prod.yml
```

### Manual Execution

**Development:**
```bash
docker stack deploy --prune -c docker-compose.yml -c docker-compose.dev.yml cerberus_dev
```

**Production:**
```bash
docker stack deploy --prune -c docker-compose.yml -c docker-compose.prod.yml cerberus
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
These are injected as environment variables into the runner, which then uses them to generate versioned Docker Secrets.
- `JWT_SECRET`
- `SESSION_SECRET`
- `POSTGRES_PASSWORD`
- `STORAGE_ENCRYPTION_KEY`
- `LLDAP_JWT_SECRET`
- `LLDAP_KEY_SEED`
- `LLDAP_LDAP_USER_PASS`
- `VW_ADMIN_TOKEN` # Argon2 hash of the admin password

**Required Repository Variables:**
- `DOMAIN_NAME`